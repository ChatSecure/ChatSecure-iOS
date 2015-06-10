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
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+XEP_0085.h"
#import "NSXMLElement+XEP_0203.h"
#import "XMPPMessageDeliveryReceipts.h"
#import "Strings.h"
#import "OTRXMPPManagedPresenceSubscriptionRequest.h"
#import "OTRYapDatabaseRosterStorage.h"

#import "OTRLog.h"

#import <CFNetwork/CFNetwork.h>

#import "OTRSettingsManager.h"
#import "OTRConstants.h"
#import "OTRProtocolManager.h"
#include <stdlib.h>
#import "XMPPXOAuth2Google.h"
#import "OTRConstants.h"
#import "OTRUtilities.h"

#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "OTRXMPPBuddy.h"
#import "OTRXMPPAccount.h"
#import "OTRMessage.h"
#import "OTRAccount.h"
#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "OTRvCardYapDatabaseStorage.h"
#import "OTRNotificationController.h"

NSString *const OTRXMPPRegisterSucceededNotificationName = @"OTRXMPPRegisterSucceededNotificationName";
NSString *const OTRXMPPRegisterFailedNotificationName    = @"OTRXMPPRegisterFailedNotificationName";

static NSString *const kOTRXMPPErrorDomain = @"kOTRXMPPErrorDomain";

NSTimeInterval const kOTRChatStatePausedTimeout   = 5;
NSTimeInterval const kOTRChatStateInactiveTimeout = 120;

NSString *const OTRXMPPLoginStatusNotificationName = @"OTRXMPPLoginStatusNotificationName";

NSString *const OTRXMPPOldLoginStatusKey = @"OTRXMPPOldLoginStatusKey";
NSString *const OTRXMPPNewLoginStatusKey = @"OTRXMPPNewLoginStatusKey";
NSString *const OTRXMPPLoginErrorKey = @"OTRXMPPLoginErrorKey";


@interface OTRXMPPManager()

@property (nonatomic) OTRProtocolConnectionStatus connectionStatus;

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) XMPPJID *JID;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) OTRYapDatabaseRosterStorage * xmppRosterStorage;
@property (nonatomic, strong) OTRCertificatePinning * certificatePinningModule;
@property (nonatomic, strong) NSMutableDictionary * buddyTimers;
@property (nonatomic) dispatch_queue_t workQueue;
@property (nonatomic) BOOL isRegisteringNewAccount;
@property (nonatomic) BOOL userInitiatedConnection;
@property (nonatomic) OTRLoginStatus loginStatus;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;
- (void)failedToConnect:(NSError *)error;

@end


@implementation OTRXMPPManager

- (id)init
{
    if (self = [super init]) {
        NSString * queueLabel = [NSString stringWithFormat:@"%@.work.%@",[self class],self];
        self.workQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.connectionStatus = OTRProtocolConnectionStatusDisconnected;
        self.buddyTimers = [NSMutableDictionary dictionary];
        self.databaseConnection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
    }
    return self;
}

- (id) initWithAccount:(OTRAccount *)newAccount {
    if(self = [self init])
    {
        NSAssert([newAccount isKindOfClass:[OTRXMPPAccount class]], @"Must have XMPP account");
        self.isRegisteringNewAccount = NO;
        _account = (OTRXMPPAccount *)newAccount;
        
        // Setup the XMPP stream
        [self setupStream];
        
        self.buddyTimers = [NSMutableDictionary dictionary];
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
    
	self.xmppStream = [[XMPPStream alloc] init];
    
    //Used to fetch correct account from XMPPStream in delegate methods especailly
    self.xmppStream.tag = self.account.uniqueId;
    
    self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicyRequired;
    
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
	
    OTRYapDatabaseRosterStorage * rosterStorage = [[OTRYapDatabaseRosterStorage alloc] init];
	
	self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:rosterStorage];
	
	self.xmppRoster.autoFetchRoster = YES;
    self.xmppRoster.autoClearAllUsersAndResources = NO;
	self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	// 
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
    OTRvCardYapDatabaseStorage * vCardStorage  = [[OTRvCardYapDatabaseStorage alloc] init];
	self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:vCardStorage];
	
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
	
	self.xmppCapabilitiesStorage = [[XMPPCapabilitiesCoreDataStorage alloc] initWithInMemoryStore];
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
    
	[self.xmppStream addDelegate:self delegateQueue:self.workQueue];
	[self.xmppRoster addDelegate:self delegateQueue:self.workQueue];
    [self.xmppCapabilities addDelegate:self delegateQueue:self.workQueue];
    
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
    [_xmppCapabilities removeDelegate:self];

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

- (XMPPStream *)xmppStream
{
    if(!_xmppStream)
    {
        _xmppStream = [[XMPPStream alloc] init];
        _xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicyRequired;
    }
    return _xmppStream;
}

- (void)goOnline
{
    self.connectionStatus = OTRProtocolConnectionStatusConnected;
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

- (NSString *)accountDomainWithError:(id)error;
{
    return self.account.domain;
}

- (void)didRegisterNewAccountWithStream:(XMPPStream *)stream
{
    self.isRegisteringNewAccount = NO;
    [self authenticateWithStream:stream];
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
    
    self.JID = [XMPPJID jidWithString:myJID resource:resource];
    
	[self.xmppStream setMyJID:self.JID];
    
    self.password = myPassword;
}

- (void)authenticateWithStream:(XMPPStream *)stream {
    NSError * error = nil;
    BOOL status = YES;
    if ([stream supportsXOAuth2GoogleAuthentication] && self.account.accountType == OTRAccountTypeGoogleTalk) {
        status = [stream authenticateWithGoogleAccessToken:self.password error:&error];
    }
    else {
        status = [stream authenticateWithPassword:self.password error:&error];
    }
}

///////////////////////////////
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
    self.connectionStatus = OTRProtocolConnectionStatusConnecting;
    
    self.JID = [XMPPJID jidWithString:myJID resource:self.account.resource];
    
    if (![self.JID.domain isEqualToString:self.xmppStream.myJID.domain]) {
        [self.xmppStream disconnect];
    }
    
	[self.xmppStream setMyJID:self.JID];
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
    NSString * domainString = [self accountDomainWithError:error];
    if (error) {
        [self failedToConnect:error];
        return NO;
    }
    if ([domainString length]) {
        [self.xmppStream setHostName:domainString];
    }
    
    [self.xmppStream setHostPort:self.account.port];
	
    
	error = nil;
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
    
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSArray *buddiesArray = [self.account allBuddiesWithTransaction:transaction];
        for (OTRXMPPBuddy *buddy in buddiesArray) {
            buddy.status = OTRBuddyStatusOffline;
            buddy.chatState = kOTRChatStateGone;
            
            [buddy saveWithTransaction:transaction];
        }
    } completionQueue:dispatch_get_main_queue() completionBlock:^{
        if([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect])
        {
            [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [OTRMessage deleteAllMessagesForAccountId:self.account.uniqueId transaction:transaction];
            }];
        }
    }];
}

- (void)registerNewAccountWithPassword:(NSString *)newPassword
{
    self.isRegisteringNewAccount = YES;
    if (self.xmppStream.isConnected) {
        [self.xmppStream disconnect];
    }
    
    [self connectWithJID:self.account.username password:newPassword];
}

- (void)registerNewAccountWithPassword:(NSString *)newPassword stream:(XMPPStream *)stream
{
    NSError * error = nil;
    if ([stream supportsInBandRegistration]) {
        [stream registerWithPassword:self.password error:&error];
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
    if (![[stream.myJID bare] isEqualToString:self.account.username] || ![[stream.myJID resource] isEqualToString:self.account.resource])
    {
        self.account.username = [stream.myJID bare];
        self.account.resource = [stream.myJID resource];
        [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [self.account saveWithTransaction:transaction];
        }];
    }
}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket 
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self changeLoginStatus:OTRLoginStatusConnected error:nil];
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    settings[GCDAsyncSocketSSLProtocolVersionMin] = @(kTLSProtocol1);
    settings[GCDAsyncSocketSSLCipherSuites] = [OTRUtilities cipherSuites];
    settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);
    
    [self changeLoginStatus:OTRLoginStatusSecuring error:nil];
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [self changeLoginStatus:OTRLoginStatusSecured error:nil];
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if (self.isRegisteringNewAccount) {
        [self registerNewAccountWithPassword:self.password stream:sender];
    }
    else{
        [self authenticateWithStream:sender];
    }
    
    [self changeLoginStatus:OTRLoginStatusAuthenticating error:nil];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error);
    
    self.connectionStatus = OTRProtocolConnectionStatusDisconnected;
    
    [self changeLoginStatus:OTRLoginStatusDisconnected error:error];
    
    if (self.loginStatus == OTRLoginStatusDisconnected)
    {
        DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        
        [self failedToConnect:error];
    }
    
    //Reset buddy info to offline
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSArray *allBuddies = [self.account allBuddiesWithTransaction:transaction];
        [allBuddies enumerateObjectsUsingBlock:^(OTRXMPPBuddy *buddy, NSUInteger idx, BOOL *stop) {
            buddy.status = OTRBuddyStatusOffline;
            buddy.statusMessage = nil;
            [transaction setObject:buddy forKey:buddy.uniqueId inCollection:[OTRXMPPBuddy collection]];
        }];
        
    }];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.connectionStatus = OTRProtocolConnectionStatusConnected;
	[self goOnline];
    
    
    [self changeLoginStatus:OTRLoginStatusAuthenticated error:nil];
    
    
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    self.connectionStatus = OTRProtocolConnectionStatusDisconnected;
    NSError *err = [OTRXMPPError errorForXMLElement:error];
    [self failedToConnect:err];
    
    [self changeLoginStatus:OTRLoginStatusSecured error:err];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [iq elementID]);
	return NO;
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    [self didRegisterNewAccountWithStream:sender];
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)xmlError {
    
    self.isRegisteringNewAccount = NO;
    NSError * error = [OTRXMPPError errorForXMLElement:xmlError];
    [self failedToRegisterNewAccount:error];
    
    [self changeLoginStatus:OTRLoginStatusSecured error:error];
}

-(OTRXMPPBuddy *)buddyWithMessage:(XMPPMessage *)message transaction:(YapDatabaseReadTransaction *)transaction
{
    OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyWithUsername:[[message from] bare] withAccountUniqueId:self.account.uniqueId transaction:transaction];
    return buddy;
}


- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)xmppMessage
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        OTRXMPPBuddy *messageBuddy = [self buddyWithMessage:xmppMessage transaction:transaction];

        if ([xmppMessage isErrorMessage]) {
            NSError *error = [xmppMessage errorMessage];
            DDLogCWarn(@"XMPP Error: %@",error);
        }
        else if([xmppMessage hasChatState])
        {
            if([xmppMessage hasComposingChatState])
                messageBuddy.chatState = kOTRChatStateComposing;
            else if([xmppMessage hasPausedChatState])
                 messageBuddy.chatState = kOTRChatStatePaused;
            else if([xmppMessage hasActiveChatState])
                 messageBuddy.chatState = kOTRChatStateActive;
            else if([xmppMessage hasInactiveChatState])
                 messageBuddy.chatState = kOTRChatStateInactive;
            else if([xmppMessage hasGoneChatState])
                 messageBuddy.chatState = kOTRChatStateGone;
            [messageBuddy saveWithTransaction:transaction];
        }
        
        
        if ([xmppMessage hasReceiptResponse] && ![xmppMessage isErrorMessage]) {
            [OTRMessage receivedDeliveryReceiptForMessageId:[xmppMessage receiptResponseID] transaction:transaction];
        }
        
        if ([xmppMessage isMessageWithBody] && ![xmppMessage isErrorMessage])
        {
            NSString *body = [[xmppMessage elementForName:@"body"] stringValue];
            
            NSDate * date = [xmppMessage delayedDeliveryDate];
            
            OTRMessage *message = [[OTRMessage alloc] init];
            message.incoming = YES;
            message.text = body;
            message.buddyUniqueId = messageBuddy.uniqueId;
            if (date) {
                message.date = date;
            }
            
            message.messageId = [xmppMessage elementID];
            
            if (messageBuddy) {
                [[OTRKit sharedInstance] decodeMessage:message.text username:messageBuddy.username accountName:self.account.username protocol:kOTRProtocolTypeXMPP tag:message];
            } else {
                // message from server
                DDLogWarn(@"No buddy for message: %@", xmppMessage);
            }
        }
        if (messageBuddy) {
            [transaction setObject:messageBuddy forKey:messageBuddy.uniqueId inCollection:[OTRXMPPBuddy collection]];
        }
    }];
}
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@\nType: %@\nShow: %@\nStatus: %@", THIS_FILE, THIS_METHOD, [presence from], [presence type], [presence show],[presence status]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    if ([message.elementID length]) {
        [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [OTRMessage enumerateMessagesWithMessageId:message.elementID transaction:transaction usingBlock:^(OTRMessage *message, BOOL *stop) {
                message.error = error;
                [message saveWithTransaction:transaction];
                *stop = YES;
            }];
        }];
    }
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}
- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	NSString *jidStrBare = [presence fromStr];
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRXMPPPresenceSubscriptionRequest *request = [OTRXMPPPresenceSubscriptionRequest fetchPresenceSubscriptionRequestWithJID:jidStrBare accontUniqueId:self.account.uniqueId transaction:transaction];
        if (!request) {
            request = [[OTRXMPPPresenceSubscriptionRequest alloc] init];
        }
        
        request.jid = jidStrBare;
        request.accountUniqueId = self.account.uniqueId;
        
        [request saveWithTransaction:transaction];
    }];
}

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    //verry unclear what this delegate call is supposed to do with jabber.ccc.de it seems to have all the subscription=both,none and jid
    /*
    if ([iq isSetIQ] && [[[[[[iq elementsForName:@"query"] firstObject] elementsForName:@"item"] firstObject] attributeStringValueForName:@"subscription"] isEqualToString:@"from"]) {
        NSString *jidString = [[[[[iq elementsForName:@"query"] firstObject] elementsForName:@"item"] firstObject] attributeStringValueForName:@"jid"];
        
        [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            OTRXMPPPresenceSubscriptionRequest *request = [OTRXMPPPresenceSubscriptionRequest fetchPresenceSubscriptionRequestWithJID:jidString accontUniqueId:self.account.uniqueId transaction:transaction];
            if (!request) {
                request = [[OTRXMPPPresenceSubscriptionRequest alloc] init];
            }
            
            request.jid = jidString;
            request.accountUniqueId = self.account.uniqueId;
            
            [transaction setObject:request forKey:request.uniqueId inCollection:[OTRXMPPPresenceSubscriptionRequest collection]];
        }];
    }
    else if ([iq isSetIQ] && [[[[[[iq elementsForName:@"query"] firstObject] elementsForName:@"item"] firstObject] attributeStringValueForName:@"subscription"] isEqualToString:@"none"])
    {
        [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSString *jidString = [[[[[iq elementsForName:@"query"] firstObject] elementsForName:@"item"] firstObject] attributeStringValueForName:@"jid"];
            
            OTRXMPPBuddy *buddy = [[OTRXMPPBuddy fetchBuddyWithUsername:jidString withAccountUniqueId:self.account.uniqueId transaction:transaction] copy];
            buddy.pendingApproval = YES;
            [buddy saveWithTransaction:transaction];
        }];
    }
    
    */
    
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OTRProtocol 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendMessage:(OTRMessage*)message
{
    NSString *text = message.text;
    
    __block OTRBuddy *buddy = nil;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [message buddyWithTransaction:transaction];
    }];
    
    [self invalidatePausedChatStateTimerForBuddyUniqueId:buddy.uniqueId];
    
    if ([text length])
    {
        NSString * messageID = message.messageId;
        XMPPMessage * xmppMessage = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:buddy.username] elementID:messageID];
        [xmppMessage addBody:text];

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

- (void) connectWithPassword:(NSString *)password userInitiated:(BOOL)userInitiated
{
    // Don't issue a reconnect if we're already connected and authenticated
    if ([self.xmppStream isConnected] && [self.xmppStream isAuthenticated]) {
        return;
    }
    self.userInitiatedConnection = userInitiated;
    [self connectWithJID:self.account.username password:password];
    if (self.userInitiatedConnection) {
        [[OTRNotificationController sharedInstance] showAccountConnectingNotificationWithAccountName:self.account.username];
    }
}

-(void)connectWithPassword:(NSString *)password
{
    [self connectWithPassword:password userInitiated:NO];
}

-(void)sendChatState:(OTRChatState)chatState withBuddyID:(NSString *)buddyUniqueId
{
    
    
    dispatch_async(self.workQueue, ^{
        
        __block OTRXMPPBuddy *buddy = nil;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [OTRXMPPBuddy fetchObjectWithUniqueID:buddyUniqueId transaction:transaction];
        }];
        
        if (buddy.lastSentChatState == chatState) {
            return;
        }
        
        XMPPMessage * xMessage = [[XMPPMessage alloc] initWithType:@"chat" to:[XMPPJID jidWithString:buddy.username]];
        BOOL shouldSend = YES;
        
        if (chatState == kOTRChatStateActive) {
            //Timers
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self pausedChatStateTimerForBuddyObjectID:buddyUniqueId] invalidate];
                [self restartInactiveChatStateTimerForBuddyObjectID:buddyUniqueId];
            });
            
            [xMessage addActiveChatState];
        }
        else if (chatState == kOTRChatStateComposing)
        {
            if(buddy.lastSentChatState !=kOTRChatStateComposing)
                [xMessage addComposingChatState];
            else
                shouldSend = NO;
            
            //Timers
            dispatch_async(dispatch_get_main_queue(), ^{
                [self restartPausedChatStateTimerForBuddyObjectID:buddy.uniqueId];
                [[self inactiveChatStateTimerForBuddyObjectID:buddy.uniqueId] invalidate];
            });
        }
        else if(chatState == kOTRChatStateInactive)
        {
            if(buddy.lastSentChatState != kOTRChatStateInactive)
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
            [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                OTRXMPPBuddy *localBuddy = [OTRXMPPBuddy fetchObjectWithUniqueID:buddy.uniqueId transaction:transaction];
                localBuddy.lastSentChatState = chatState;
                
                [localBuddy saveWithTransaction:transaction];
            }];
            [self.xmppStream sendElement:xMessage];
        }
    });
}

- (void) addBuddy:(OTRXMPPBuddy *)newBuddy
{
    XMPPJID * newJID = [XMPPJID jidWithString:newBuddy.username];
    [self.xmppRoster addUser:newJID withNickname:newBuddy.displayName];
}
- (void) setDisplayName:(NSString *) newDisplayName forBuddy:(OTRXMPPBuddy *)buddy
{
    XMPPJID * jid = [XMPPJID jidWithString:buddy.username];
    [self.xmppRoster setNickname:newDisplayName forUser:jid];
    
}
-(void)removeBuddies:(NSArray *)buddies
{
    for (OTRXMPPBuddy *buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.username];
        [self.xmppRoster removeUser:jid];
    }
    
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectsForKeys:[buddies valueForKey:NSStringFromSelector(@selector(uniqueId))] inCollection:[OTRXMPPBuddy collection]];
    }];



}
-(void)blockBuddies:(NSArray *)buddies
{
    for (OTRXMPPBuddy *buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.username];
        [self.xmppRoster revokePresencePermissionFromUser:jid];
    }
}

//Chat State

-(OTRXMPPBudyTimers *)buddyTimersForBuddyObjectID:(NSString *)
managedBuddyObjectID
{
    OTRXMPPBudyTimers * timers = (OTRXMPPBudyTimers *)[self.buddyTimers objectForKey:managedBuddyObjectID];
    return timers;
}

-(NSTimer *)inactiveChatStateTimerForBuddyObjectID:(NSString *)
managedBuddyObjectID
{
   return [self buddyTimersForBuddyObjectID:managedBuddyObjectID].inactiveChatStateTimer;
    
}
-(NSTimer *)pausedChatStateTimerForBuddyObjectID:(NSString *)
managedBuddyObjectID
{
    return [self buddyTimersForBuddyObjectID:managedBuddyObjectID].pausedChatStateTimer;
}

-(void)restartPausedChatStateTimerForBuddyObjectID:(NSString *)managedBuddyObjectID
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
-(void)restartInactiveChatStateTimerForBuddyObjectID:(NSString *)managedBuddyObjectID
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
    NSString * managedBuddyObjectID= (NSString *)timer.userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        [timer invalidate];
    });
    [self sendChatState:kOTRChatStatePaused withBuddyID:managedBuddyObjectID];
}
-(void)sendInactiveChatState:(NSTimer *)timer
{
    NSString *managedBuddyObjectID= (NSString *)timer.userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        [timer invalidate];
    });
    
    [self sendChatState:kOTRChatStateInactive withBuddyID:managedBuddyObjectID];
}

- (void)invalidatePausedChatStateTimerForBuddyUniqueId:(NSString *)buddyUniqueId
{
    [[self pausedChatStateTimerForBuddyObjectID:buddyUniqueId] invalidate];
}

- (void)failedToConnect:(NSError *)error
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        NSMutableDictionary *userInfo = [@{kOTRProtocolLoginUserInitiated : @(self.userInitiatedConnection)} mutableCopy];
        if (error) {
            [userInfo setObject:error forKey:kOTRNotificationErrorKey];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolLoginFail object:self userInfo:userInfo];
        //Only user initiated on the first time any subsequent attempts will not be from user
        strongSelf.userInitiatedConnection = NO;
    });
}

- (OTRCertificatePinning *)certificatePinningModule
{
    if(!_certificatePinningModule){
        _certificatePinningModule = [OTRCertificatePinning defaultCertificates];
        _certificatePinningModule.delegate = self;
    }
    return _certificatePinningModule;
}

- (void)newTrust:(SecTrustRef)trust withHostName:(NSString *)hostname systemTrustResult:(SecTrustResultType)trustResultType
{
    NSData * certifcateData = [OTRCertificatePinning dataForCertificate:[OTRCertificatePinning certForTrust:trust]];
    DDLogVerbose(@"New trustResultType: %d certLength: %d", (int)trustResultType, (int)certifcateData.length);
    NSError *error = [OTRXMPPError errorForTrustResult:trustResultType withCertData:certifcateData hostname:hostname];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self failedToConnect:error];
    });
    
    [self changeLoginStatus:OTRLoginStatusDisconnected error:error];
}

- (void)changeLoginStatus:(OTRLoginStatus)status error:(NSError *)error
{
    OTRLoginStatus oldStatus = self.loginStatus;
    OTRLoginStatus newStatus = status;
    self.loginStatus = status;
    
    NSMutableDictionary *userInfo = [@{OTRXMPPOldLoginStatusKey: @(oldStatus), OTRXMPPNewLoginStatusKey: @(newStatus)} mutableCopy];
    
    if (error) {
        userInfo[OTRXMPPLoginErrorKey] = error;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OTRXMPPLoginStatusNotificationName object:self userInfo:userInfo];
    });
}

@end
