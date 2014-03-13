//
//  OTRXMPPManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/7/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRXMPPManager.h"

#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+XEP_0085.h"
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessageDeliveryReceipts.h"
#import "Strings.h"
#import "OTRXMPPManagedPresenceSubscriptionRequest.h"
#import "OTRRosterStorage.h"
#import "OTRCapabilitiesInMemoryCoreDataStorage.h"
#import "OTRvCardCoreDataStorage.h"

#import "OTRLog.h"

#import <CFNetwork/CFNetwork.h>

#import "OTRSettingsManager.h"
#import "OTRConstants.h"
#import "OTRProtocolManager.h"
#include <stdlib.h>
#import "XMPPXFacebookPlatformAuthentication.h"
#import "XMPPXOAuth2Google.h"
#import "OTRConstants.h"
#import "OTRUtilities.h"

@interface OTRXMPPManager()

@property (nonatomic, strong) OTRManagedXMPPAccount * account;
@property (nonatomic) BOOL isConnected;

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) XMPPJID *JID;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) OTRRosterStorage * xmppRosterStorage;
@property (nonatomic, strong) OTRCertificatePinning * certificatePinningModule;
@property (nonatomic, readwrite) BOOL isXmppConnected;
@property (nonatomic, strong) NSMutableDictionary * buddyTimers;
@property (nonatomic) dispatch_queue_t workQueue;

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;
- (void)failedToConnect:(id)error;

@end


@implementation OTRXMPPManager

- (id)init
{
    if (self = [super init]) {
        NSString * queueLabel = [NSString stringWithFormat:@"%@.work.%@",[self class],self];
        self.workQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.isConnected = NO;
        self.buddyTimers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) initWithAccount:(OTRManagedAccount *)newAccount {
    if(self = [self init])
    {
        NSAssert([newAccount isKindOfClass:[OTRManagedXMPPAccount class]], @"Must have XMPP account");
        self.account = (OTRManagedXMPPAccount*)newAccount;
        
        // Setup the XMPP stream
        [self setupStream];
    }
    
    return self;
}

- (OTRManagedAccount *)account
{
    return _account;
}

- (BOOL)isConnected
{
    return _isConnected;
}

- (void)dealloc
{
	[self teardownStream];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setupStream
{
	NSAssert(self.xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	// 
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	if (self.account.accountType == OTRAccountTypeFacebook) {
        self.xmppStream = [[XMPPStream alloc] initWithFacebookAppId:FACEBOOK_APP_ID];
    } else {
        self.xmppStream = [[XMPPStream alloc] init];
    }
    
    self.xmppStream.autoStartTLS = YES;
    self.xmppStream.requireTLS = YES;
    
    [self.certificatePinningModule activate:self.xmppStream];
    
    XMPPMessageDeliveryReceipts * deliveryReceiptsMoodule = [[XMPPMessageDeliveryReceipts alloc] init];
    deliveryReceiptsMoodule.autoSendMessageDeliveryReceipts = YES;
    deliveryReceiptsMoodule.autoSendMessageDeliveryRequests = YES;
    [deliveryReceiptsMoodule activate:self.xmppStream];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		// 
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		self.xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	// 
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	self.xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	// 
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
    
    //DDLogInfo(@"Unique Identifier: %@",self.account.uniqueIdentifier);
	
    //xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:self.account.uniqueIdentifier];
    //  xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
    OTRRosterStorage * rosterStorage = [[OTRRosterStorage alloc] init];
	
	self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:rosterStorage];
	
	self.xmppRoster.autoFetchRoster = YES;
	self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	// 
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	//xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    OTRvCardCoreDataStorage * vCardCoreDataStorage  = [[OTRvCardCoreDataStorage alloc] init];
	self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:vCardCoreDataStorage];
	
	self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
	
	// Setup capabilities
	// 
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	// 
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	// 
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	self.xmppCapabilitiesStorage = [OTRCapabilitiesInMemoryCoreDataStorage sharedInstance];
    self.xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:self.xmppCapabilitiesStorage];
    
    self.xmppCapabilities.autoFetchHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    
	// Activate xmpp modules
    
	[self.xmppReconnect         activate:self.xmppStream];
	[self.xmppRoster            activate:self.xmppStream];
	[self.xmppvCardTempModule   activate:self.xmppStream];
	[self.xmppvCardAvatarModule activate:self.xmppStream];
	[self.xmppCapabilities      activate:self.xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
	[self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppCapabilities addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// Optional:
	// 
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	// 
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	// 
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];	
}

- (void)teardownStream
{
    [_xmppStream removeDelegate:self];
    [_xmppRoster removeDelegate:self];

    [_xmppReconnect         deactivate];
    [_xmppRoster            deactivate];
    [_xmppvCardTempModule   deactivate];
    [_xmppvCardAvatarModule deactivate];
    [_xmppCapabilities      deactivate];

    [_xmppStream disconnect];

    _xmppStream = nil;
    _xmppReconnect = nil;
    _xmppRoster = nil;
    _xmppRosterStorage = nil;
    _xmppvCardStorage = nil;
    _xmppvCardTempModule = nil;
    _xmppvCardAvatarModule = nil;
    _xmppCapabilities = nil;
    _xmppCapabilitiesStorage = nil;
    _certificatePinningModule = nil;
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
// 
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
// 
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
// 
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

- (void)goOnline
{
    self.isConnected = YES;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolLoginSuccess object:self];
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[[self xmppStream] sendElement:presence];
    //[self fetchedResultsController];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

- (void)failedToConnect:(id)error
{
    NSError *localError = nil;
    if ([error isKindOfClass:[NSError class]]) {
        localError = error;
    }
    if ([error isKindOfClass:[NSXMLElement class]]) {
        NSXMLElement *errorElement = error;
        NSString *errorString = [errorElement prettyXMLString];
        localError = [NSError errorWithDomain:kChatSecureErrorDomain code:-123 userInfo:@{NSLocalizedDescriptionKey: errorString}];
    }
    if (localError) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kOTRProtocolLoginFail object:self userInfo:@{kOTRProtocolLoginFailErrorKey:localError}];
    }
    else {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kOTRProtocolLoginFail object:self];
    }
    
}

////////////////////////////////////////////
#pragma mark Capabilities Collected
////////////////////////////////////////////

- (NSArray *)myFeaturesForXMPPCapabilities:(XMPPCapabilities *)sender
{
    return @[@"http://jabber.org/protocol/chatstates"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword;
{
    self.password = myPassword;
    int r = arc4random() % 99999;
    
    NSString * resource = [NSString stringWithFormat:@"%@%d",kOTRXMPPResource,r];
    
    self.JID = [XMPPJID jidWithString:myJID resource:resource];
    
	[self.xmppStream setMyJID:self.JID];
    //DDLogInfo(@"myJID %@",myJID);
	if (![self.xmppStream isDisconnected]) {
        [self xmppStreamDidConnect:self.xmppStream];
		return YES;
	}
    
	//
	// If you don't want to use the Settings view to set the JID, 
	// uncomment the section below to hard code a JID and password.
	//
	// Replace me with the proper JID and password:
	//	myJID = @"user@gmail.com/xmppframework";
	//	myPassword = @"";
    
	if (myJID == nil || myPassword == nil) {
		DDLogWarn(@"JID and password must be set before connecting!");
        
		return NO;
	}
    
    if (self.account.domain.length > 0) {
        [self.xmppStream setHostName:self.account.domain];
    }
    
    [self.xmppStream setHostPort:self.account.portValue];
	
    
	NSError *error = nil;
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		[self failedToConnect:error];
        
		DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
	return YES;
}

- (void)disconnect
{
    [self goOffline];
    
    [self.xmppStream disconnect];
    
    
    if([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect])
    {
        NSManagedObjectContext * context = [NSManagedObjectContext MR_context];
        [self.account deleteAllAccountMessagesInContext:context];
        [context MR_saveToPersistentStoreAndWait];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidChangeMyJID:(XMPPStream *)stream
{
    if (![[stream.myJID bare] isEqualToString:self.account.username])
    {
        self.account.username = [stream.myJID bare];
    }
}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket 
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [settings setObject:[OTRUtilities cipherSuites] forKey:GCDAsyncSocketSSLCipherSuites];
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	
    
	NSError *error = nil;
    
    if ([sender supportsXFacebookPlatformAuthentication]) {
        
        self.isXmppConnected = [sender authenticateWithFacebookAccessToken:self.password error:&error];
        return;
    }
    else if ([sender supportsXOAuth2GoogleAuthentication] && self.account.accountType == OTRAccountTypeGoogleTalk) {
        self.isXmppConnected = [sender authenticateWithGoogleAccessToken:self.password error:&error];
        return;
    }
	else if ([[self xmppStream] authenticateWithPassword:self.password error:&error])
	{
        self.isXmppConnected = YES;
        return;
	}
    
    self.isXmppConnected = NO;
    if(error){
        [self failedToConnect:error];
    }
    
    
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	[self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    self.isConnected = NO;
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self failedToConnect:error];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [iq elementID]);
	
	return NO;
}

-(OTRManagedBuddy *)buddyWithMessage:(XMPPMessage *)message inContext:(NSManagedObjectContext *)context
{
    OTRManagedBuddy * buddy = [OTRManagedBuddy fetchOrCreateWithName:[[message from] bare] account:self.account inContext:context];
    return buddy;
}


- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];

    
	// A simple example of inbound message handling.
    if([message hasChatState] && ![message isErrorMessage])
    {
        OTRManagedBuddy * messageBuddy = [self buddyWithMessage:message inContext:context];
        if([message hasComposingChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateComposing];
        else if([message hasPausedChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStatePaused];
        else if([message hasActiveChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateActive];
        else if([message hasInactiveChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateInactive];
        else if([message hasGoneChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateGone];
    }
    
    if ([message hasReceiptResponse] && ![message isErrorMessage]) {
        [OTRManagedMessage receivedDeliveryReceiptForMessageID:[message receiptResponseID]];
    }
    
	if ([message isMessageWithBody] && ![message isErrorMessage])
	{
        NSString *body = [[message elementForName:@"body"] stringValue];
        
        OTRManagedBuddy * messageBuddy = [self buddyWithMessage:message inContext:context];
        
        NSDate * date = [message delayedDeliveryDate];
        
        OTRManagedMessage *otrMessage = [OTRManagedMessage newMessageFromBuddy:messageBuddy message:body encrypted:YES delayedDate:date inContext:context];
        [context MR_saveToPersistentStoreAndWait];
        
        [OTRCodec decodeMessage:otrMessage completionBlock:^(OTRManagedMessage *message) {
            [OTRManagedMessage showLocalNotificationForMessage:message];
        }];
	}
    [context MR_saveToPersistentStoreAndWait];
    
}
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@\nType: %@\nShow: %@\nStatus: %@", THIS_FILE, THIS_METHOD, [presence from], [presence type], [presence show],[presence status]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolDiconnect object:self];
    
    self.isConnected = NO;
	
	if (!self.isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        [self failedToConnect:error];
	}
    else {
        NSManagedObjectContext * context = [NSManagedObjectContext MR_context];
        [self.account setAllBuddiesStatuts:OTRBuddyStatusOffline inContext:context];
  
        [context MR_saveToPersistentStoreAndWait];
        //Lost connection
    }
    self.isXmppConnected = NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	NSString *jidStrBare = [presence fromStr];
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    
    [OTRXMPPManagedPresenceSubscriptionRequest fetchOrCreateWith:jidStrBare account:self.account inContext:context];
    [context MR_saveToPersistentStoreAndWait];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OTRProtocol 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendMessage:(OTRManagedMessage*)theMessage
{
    NSString *messageStr = theMessage.message;
    
    if ([messageStr length] >0) 
    {
        NSString * messageID = [NSString stringWithFormat:@"%@",theMessage.uniqueID];
        XMPPMessage * xmppMessage = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:theMessage.buddy.accountName] elementID:messageID];
        [xmppMessage addBody:theMessage.message];

        [xmppMessage addActiveChatState];
		
		[self.xmppStream sendElement:xmppMessage];
    }
}

- (NSString*) accountName
{
    return [self.JID full];
    
}

- (NSString*) type {
    return kOTRProtocolTypeXMPP;
}

-(void)connectWithPassword:(NSString *)myPassword
{
    [self connectWithJID:self.account.username password:myPassword];
}

-(void)sendChatState:(OTRChatState)chatState withBuddyID:(NSManagedObjectID *)managedBuddyObjectID
{
    dispatch_async(self.workQueue, ^{
        NSManagedObjectContext * localContext = [NSManagedObjectContext MR_context];
        
        OTRManagedBuddy * buddy = [self managedBuddyWithObjectID:managedBuddyObjectID inContext:localContext];
        
        
        if (buddy.lastSentChatStateValue == chatState) {
            return;
        }
        
        XMPPMessage * xMessage = [[XMPPMessage alloc] initWithType:@"chat" to:[XMPPJID jidWithString:buddy.accountName]];
        
        BOOL shouldSend = YES;
        
        if (chatState == kOTRChatStateActive) {
            //Timers
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self pausedChatStateTimerForBuddyObjectID:managedBuddyObjectID] invalidate];
                [self restartInactiveChatStateTimerForBuddyObjectID:managedBuddyObjectID];
            });
            
            [xMessage addActiveChatState];
        }
        else if (chatState == kOTRChatStateComposing)
        {
            if(buddy.lastSentChatState.intValue !=kOTRChatStateComposing)
                [xMessage addComposingChatState];
            else
                shouldSend = NO;
            
            //Timers
            dispatch_async(dispatch_get_main_queue(), ^{
                [self restartPausedChatStateTimerForBuddyObjectID:managedBuddyObjectID];
                [[self inactiveChatStateTimerForBuddyObjectID:managedBuddyObjectID] invalidate];
            });
        }
        else if(chatState == kOTRChatStateInactive)
        {
            if(buddy.lastSentChatState.intValue != kOTRChatStateInactive)
                [xMessage addInactiveChatState];
            else
                shouldSend = NO;
        }
        else if (chatState == kOTRChatStatePaused)
        {
            [xMessage addPausedChatState];
        }
        else if (chatState == kOTRChatStateGone)
        {
            [xMessage addGoneChatState];
        }
        else
        {
            shouldSend = NO;
        }
        
        if(shouldSend)
        {
            [buddy setLastSentChatStateValue:chatState];
            [self.xmppStream sendElement:xMessage];
        }
        [localContext MR_saveToPersistentStoreAndWait];
    });
}

- (void) addBuddy:(OTRManagedBuddy *)newBuddy
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [newBuddy addToGroup:@"Buddies" inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    XMPPJID * newJID = [XMPPJID jidWithString:newBuddy.accountName];
    [self.xmppRoster addUser:newJID withNickname:newBuddy.displayName];
}
- (void) setDisplayName:(NSString *) newDisplayName forBuddy:(OTRManagedBuddy *)buddy
{
    XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
    [self.xmppRoster setNickname:newDisplayName forUser:jid];
    
}
-(void)removeBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
        [self.xmppRoster removeUser:jid];
        [buddy MR_deleteEntity];
    }
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];



}
-(void)blockBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
        [self.xmppRoster revokePresencePermissionFromUser:jid];
    }
}

//Chat State
-(OTRManagedBuddy *)managedBuddyWithObjectID:(NSManagedObjectID *)managedBuddyObjectID inContext:(NSManagedObjectContext *)context
{
    NSError * error = nil;
    OTRManagedBuddy * managedBuddy = (OTRManagedBuddy *)[context existingObjectWithID:managedBuddyObjectID error:&error];
    if (error) {
        DDLogError(@"Error Fetching Buddy: %@",error);
    }
    return managedBuddy;
    
}
-(OTRXMPPBudyTimers *)buddyTimersForBuddyObjectID:(NSManagedObjectID *)
managedBuddyObjectID
{
    OTRXMPPBudyTimers * timers = (OTRXMPPBudyTimers *)[self.buddyTimers objectForKey:managedBuddyObjectID];
    return timers;
}

-(NSTimer *)inactiveChatStateTimerForBuddyObjectID:(NSManagedObjectID *)
managedBuddyObjectID
{
   return [self buddyTimersForBuddyObjectID:managedBuddyObjectID].inactiveChatStateTimer;
    
}
-(NSTimer *)pausedChatStateTimerForBuddyObjectID:(NSManagedObjectID *)
managedBuddyObjectID
{
    return [self buddyTimersForBuddyObjectID:managedBuddyObjectID].pausedChatStateTimer;
}

-(void)restartPausedChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OTRXMPPBudyTimers * timer = (OTRXMPPBudyTimers *)[self.buddyTimers objectForKey:managedBuddyObjectID];
        if(!timer)
        {
            timer = [[OTRXMPPBudyTimers alloc] init];
        }
        [timer.pausedChatStateTimer invalidate];
        timer.pausedChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStatePausedTimeout target:self selector:@selector(sendPausedChatState:) userInfo:managedBuddyObjectID repeats:NO];
        [self.buddyTimers setObject:timer forKey:managedBuddyObjectID];
    });
    
}
-(void)restartInactiveChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OTRXMPPBudyTimers * timer = (OTRXMPPBudyTimers *)[self.buddyTimers objectForKey:managedBuddyObjectID];
        if(!timer)
        {
            timer = [[OTRXMPPBudyTimers alloc] init];
        }
        [timer.inactiveChatStateTimer invalidate];
        timer.inactiveChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStateInactiveTimeout target:self selector:@selector(sendInactiveChatState:) userInfo:managedBuddyObjectID repeats:NO];
        [self.buddyTimers setObject:timer forKey:managedBuddyObjectID];
    });
}
-(void)sendPausedChatState:(NSTimer *)timer
{
    NSManagedObjectID * managedBuddyObjectID= (NSManagedObjectID *)timer.userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        [timer invalidate];
    });
    [self sendChatState:kOTRChatStatePaused withBuddyID:managedBuddyObjectID];
}
-(void)sendInactiveChatState:(NSTimer *)timer
{
    NSManagedObjectID * managedBuddyObjectID= (NSManagedObjectID *)timer.userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        [timer invalidate];
    });
    
    [self sendChatState:kOTRChatStateInactive withBuddyID:managedBuddyObjectID];
}

- (OTRCertificatePinning *)certificatePinningModule
{
    if(!_certificatePinningModule){
        _certificatePinningModule = [OTRCertificatePinning defaultCertificates];
        _certificatePinningModule.delegate = self;
    }
    return _certificatePinningModule;
}

- (void)newTrust:(SecTrustRef)trust withHostName:(NSString *)hostname withStatus:(OSStatus)status; {
    DDLogVerbose(@"New trust found");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData * certifcateData = [OTRCertificatePinning dataForCertificate:[OTRCertificatePinning certForTrust:trust]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolLoginFail object:self userInfo:@{kOTRProtocolLoginFailSSLStatusKey:[NSNumber numberWithLong:status],kOTRProtocolLoginFailSSLCertificateDataKey:certifcateData,kOTRProtocolLoginFailHostnameKey:hostname}];
    });
    
    
    
}

@end
