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

NSString *const OTRXMPPRegisterSucceededNotificationName = @"OTRXMPPRegisterSucceededNotificationName";
NSString *const OTRXMPPRegisterFailedNotificationName    = @"OTRXMPPRegisterFailedNotificationName";


@interface OTRXMPPManager()

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;
- (void)failedToConnect:(NSError *)error;

@end


@implementation OTRXMPPManager

@synthesize xmppStream = _xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize account;
@synthesize buddyTimers;
@synthesize certificatePinningModule = _certificatePinningModule;
@synthesize isConnected;

- (id) initWithAccount:(OTRManagedAccount *)newAccount {
    self = [super init];
    
    if(self)
    {
        isRegisteringNewAccount = NO;
        self.isConnected = NO;
        self.account = (OTRManagedXMPPAccount*)newAccount;

        // Configure logging framework
        backgroundQueue = dispatch_queue_create("buddy.background", NULL);
        //[DDLog addLogger:[DDTTYLogger sharedInstance]];
        
        // Setup the XMPP stream
        [self setupStream];
        
        buddyTimers = [NSMutableDictionary dictionary];
    }
    
    return self;
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
	NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");

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
		
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	// 
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	xmppReconnect = [[XMPPReconnect alloc] init];
	
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
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:rosterStorage];
	
	xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	// 
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	//xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    OTRvCardCoreDataStorage * vCardCoreDataStorage  = [[OTRvCardCoreDataStorage alloc] init];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:vCardCoreDataStorage];
	
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
	
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
	
	xmppCapabilitiesStorage = [OTRCapabilitiesInMemoryCoreDataStorage sharedInstance];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    
    xmppCapabilities.autoFetchHashedCapabilities = YES;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    
	// Activate xmpp modules
    
	[xmppReconnect         activate:self.xmppStream];
	[xmppRoster            activate:self.xmppStream];
	[xmppvCardTempModule   activate:self.xmppStream];
	[xmppvCardAvatarModule activate:self.xmppStream];
	[xmppCapabilities      activate:self.xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
	[self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppCapabilities addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
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
	[self.xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
	
	[self.xmppStream disconnect];
	
	_xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
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

- (Class) xmppStreamClass {
    return [XMPPStream class];
}

- (XMPPStream *)xmppStream
{
    if(!_xmppStream)
    {
        if (self.account.accountType == OTRAccountTypeFacebook) {
            _xmppStream = [[[self xmppStreamClass] alloc] initWithFacebookAppId:FACEBOOK_APP_ID];
        }
        else{
            _xmppStream = [[[self xmppStreamClass] alloc] init];
        }
        _xmppStream.autoStartTLS = YES;
    }
    return _xmppStream;
}

- (void)goOnline
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolLoginSuccess object:self];
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

- (NSString *)accountDomainWithError:(NSError**)error;
{
    return self.account.domain;
}

- (void)failedToConnect:(NSError *)error
{
    if (error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kOTRProtocolLoginFail object:self userInfo:@{kOTRNotificationErrorKey:error}];
    }
    else {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kOTRProtocolLoginFail object:self];
    }
}

- (void)didRegisterNewAccount
{
    isRegisteringNewAccount = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:OTRXMPPRegisterSucceededNotificationName object:self];
}
- (void)failedToRegisterNewAccount:(NSError *)error
{
    if (error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:OTRXMPPRegisterFailedNotificationName object:self userInfo:@{kOTRNotificationErrorKey:error}];
    }
    else {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:OTRXMPPRegisterFailedNotificationName object:self];
    }
}

- (void)refreshStreamJID:(NSString *)myJID withPassword:(NSString *)myPassword
{
    int r = arc4random() % 99999;
    
    NSString * resource = [NSString stringWithFormat:@"%@%d",kOTRXMPPResource,r];
    
    JID = [XMPPJID jidWithString:myJID resource:resource];
    
	[self.xmppStream setMyJID:JID];
    
    password = myPassword;

}

- (void)authenticateWithStream:(XMPPStream *)stream {
    NSError * error = nil;
    BOOL status = YES;
    if ([stream supportsXFacebookPlatformAuthentication]) {
        status = [stream authenticateWithFacebookAccessToken:password error:&error];
    }
    else if ([stream supportsXOAuth2GoogleAuthentication] && self.account.accountType == OTRAccountTypeGoogleTalk) {
        status = [stream authenticateWithGoogleAccessToken:password error:&error];
    }
    else {
        status = [stream authenticateWithPassword:password error:&error];
    }
}

///////////////////////////////
#pragma mark Capabilities Collected

- (NSArray *)myFeaturesForXMPPCapabilities:(XMPPCapabilities *)sender
{
    return @[@"http://jabber.org/protocol/chatstates"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword;
{
    if (myJID == nil || myPassword == nil) {
		DDLogWarn(@"JID and password must be set before connecting!");
		return NO;
	}
    
    [self refreshStreamJID:myJID withPassword:myPassword];
    
    //DDLogInfo(@"myJID %@",myJID);
	if (![self.xmppStream isDisconnected]) {
        [self authenticateWithStream:self.xmppStream];
		return YES;
	}
    
	//
	// If you don't want to use the Settings view to set the JID, 
	// uncomment the section below to hard code a JID and password.
	//
	// Replace me with the proper JID and password:
	//	myJID = @"user@gmail.com/xmppframework";
	//	myPassword = @"";
    
	
    
    
    NSError * error = nil;
    NSString * domainString = [self accountDomainWithError:&error];
    if (error) {
        [self failedToConnect:error];
        return;
    }
    if (domainString.length) {
        [self.xmppStream setHostName:domainString];
    }
    
    [self.xmppStream setHostPort:self.account.portValue];
	
    
	error = nil;
	if (![self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting" 
		                                                    message:@"See console for error details." 
		                                                   delegate:nil 
		                                          cancelButtonTitle:@"Ok" 
		                                          otherButtonTitles:nil];
		[alertView show];
        
		DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
	return YES;
}

- (void)disconnect {
    [self goOffline];
    
    [self.xmppStream disconnect];
    
    [self.account setAllBuddiesStatuts:OTRBuddyStatusOffline];
    
    if([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect])
    {
        [self.account deleteAllConversationsForAccount];
    }
    
    [self.xmppRosterStorage clearAllUsersAndResourcesForXMPPStream:self.xmppStream];
    
}

- (void)registerNewAccountWithPassword:(NSString *)newPassword
{
    isRegisteringNewAccount = YES;
    if (self.xmppStream.isConnected) {
        [self registerNewAccountWithPassword:newPassword stream:self.xmppStream];
    }
    else {
        [self connectWithJID:self.account.username password:newPassword];
    }
}

- (void)registerNewAccountWithPassword:(NSString *)newPassword stream:(XMPPStream *)stream
{
    NSError * error = nil;
    if ([stream supportsInBandRegistration]) {
        [stream registerWithPassword:password error:&error];
        if(error)
        {
            [self failedToRegisterNewAccount:error];
        }
    }
    else{
        error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPUnsupportedAction userInfo:nil];
        [self failedToRegisterNewAccount:error];
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
    
    if (isRegisteringNewAccount) {
        [self registerNewAccountWithPassword:password stream:sender];
    }
    else{
        [self authenticateWithStream:sender];
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.isConnected = YES;
	[self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.isConnected = NO;
    [self failedToConnect:[OTRXMPPError errorForXMLElement:error]];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [iq elementID]);
	return NO;
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    [self didRegisterNewAccount];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)xmlError {
    
    isRegisteringNewAccount = NO;
    NSError * error = [OTRXMPPError errorForXMLElement:xmlError];
    [self failedToRegisterNewAccount:error];
}

-(OTRManagedBuddy *)buddyWithMessage:(XMPPMessage *)message
{
    return [OTRManagedBuddy fetchOrCreateWithName:[[message from] bare] account:self.account];
}


- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	// A simple example of inbound message handling.
    if([message hasChatState] && ![message isErrorMessage])
    {
        OTRManagedBuddy * messageBuddy = [self buddyWithMessage:message];
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
        [OTRManagedChatMessage receivedDeliveryReceiptForMessageID:[message receiptResponseID]];
    }
    
	if ([message isMessageWithBody] && ![message isErrorMessage])
	{
        NSString *body = [[message elementForName:@"body"] stringValue];
        
        OTRManagedBuddy * messageBuddy = [self buddyWithMessage:message];
        
        NSDate * date = [message delayedDeliveryDate];
        
        
        OTRManagedChatMessage *otrMessage = [OTRManagedChatMessage newMessageFromBuddy:messageBuddy message:body encrypted:YES delayedDate:date];
        [OTRCodec decodeMessage:otrMessage completionBlock:^(OTRManagedMessage *message) {
            [OTRManagedMessage showLocalNotificationForMessage:message];
        }];
	}
    
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
    
	if (!self.isConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        [self failedToConnect:error];
	}
    else {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kOTRProtocolDiconnect object:self];
    }
    self.isConnected = NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	NSString *jidStrBare = [presence fromStr];
    
    [OTRXMPPManagedPresenceSubscriptionRequest fetchOrCreateWith:jidStrBare account:self.account];
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OTRProtocol 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendMessage:(OTRManagedChatMessage*)theMessage
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
    return [JID full];
    
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OTRManagedBuddy * buddy = [self managedBuddyWithObjectID:managedBuddyObjectID];
        
        
        if (buddy.lastSentChatStateValue == chatState) {
            return;
        }
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:buddy.accountName];
        XMPPMessage * xMessage = [XMPPMessage messageFromElement:message];
        
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
            NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
            [context MR_saveToPersistentStoreAndWait];
            [self.xmppStream sendElement:message];
        }

    });
}

- (void) addBuddy:(OTRManagedBuddy *)newBuddy
{
    [newBuddy addToGroup:@"Buddies"];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    XMPPJID * newJID = [XMPPJID jidWithString:newBuddy.accountName];
    [xmppRoster addUser:newJID withNickname:newBuddy.displayName];
}
- (void) setDisplayName:(NSString *) newDisplayName forBuddy:(OTRManagedBuddy *)buddy
{
    XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
    [xmppRoster setNickname:newDisplayName forUser:jid];
    
}
-(void)removeBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
        [xmppRoster removeUser:jid];
        [buddy MR_deleteEntity];
    }
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];



}
-(void)blockBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
        [xmppRoster revokePresencePermissionFromUser:jid];
    }
}

//Chat State
-(OTRManagedBuddy *)managedBuddyWithObjectID:(NSManagedObjectID *)managedBuddyObjectID
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
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
    OTRXMPPBudyTimers * timers = (OTRXMPPBudyTimers *)[buddyTimers objectForKey:managedBuddyObjectID];
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
    OTRXMPPBudyTimers * timer = (OTRXMPPBudyTimers *)[buddyTimers objectForKey:managedBuddyObjectID];
    if(!timer)
    {
        timer = [[OTRXMPPBudyTimers alloc] init];
    }
    [timer.pausedChatStateTimer invalidate];
    timer.pausedChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStatePausedTimeout target:self selector:@selector(sendPausedChatState:) userInfo:managedBuddyObjectID repeats:NO];
    [buddyTimers setObject:timer forKey:managedBuddyObjectID];
}
-(void)restartInactiveChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID
{
    OTRXMPPBudyTimers * timer = (OTRXMPPBudyTimers *)[buddyTimers objectForKey:managedBuddyObjectID];
    if(!timer)
    {
        timer = [[OTRXMPPBudyTimers alloc] init];
    }
    [timer.inactiveChatStateTimer invalidate];
    timer.inactiveChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStateInactiveTimeout target:self selector:@selector(sendInactiveChatState:) userInfo:managedBuddyObjectID repeats:NO];
    [buddyTimers setObject:timer forKey:managedBuddyObjectID];
    
}
-(void)sendPausedChatState:(NSTimer *)timer
{
    NSManagedObjectID * managedBuddyObjectID= (NSManagedObjectID *)timer.userInfo;
    [timer invalidate];
    [self sendChatState:kOTRChatStatePaused withBuddyID:managedBuddyObjectID];
}
-(void)sendInactiveChatState:(NSTimer *)timer
{
    NSManagedObjectID * managedBuddyObjectID= (NSManagedObjectID *)timer.userInfo;
    [timer invalidate];
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
        [self failedToConnect:[OTRXMPPError errorForSSLSatus:status withCertData:certifcateData hostname:hostname]];
    });
    
    
    
}

@end
