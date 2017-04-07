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

@import CocoaAsyncSocket;
@import XMPPFramework;
#import "OTRYapDatabaseRosterStorage.h"

#import "OTRLog.h"

#import <CFNetwork/CFNetwork.h>

#import "OTRSettingsManager.h"
#import "OTRConstants.h"
#import "OTRProtocolManager.h"
#include <stdlib.h>
#import "OTRConstants.h"
#import "OTRUtilities.h"

#import "OTRDatabaseManager.h"
@import YapDatabase;
#import "OTRXMPPBuddy.h"
#import "OTRXMPPAccount.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRAccount.h"
#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "OTRvCardYapDatabaseStorage.h"
#import "OTRNotificationController.h"
#import "OTRStreamManagementYapStorage.h"
@import OTRKit;
#import "OTRXMPPRoomManager.h"
#import "OTRXMPPBuddyTimers.h"
#import "OTRXMPPError.h"
#import "OTRXMPPManager_Private.h"
#import "OTRBuddyCache.h"
#import "UIImage+ChatSecure.h"
#import "XMPPPushModule.h"
@import OTRAssets;

NSString *const OTRXMPPRegisterSucceededNotificationName = @"OTRXMPPRegisterSucceededNotificationName";
NSString *const OTRXMPPRegisterFailedNotificationName    = @"OTRXMPPRegisterFailedNotificationName";

NSTimeInterval const kOTRChatStatePausedTimeout   = 5;
NSTimeInterval const kOTRChatStateInactiveTimeout = 120;

NSString *const OTRXMPPLoginStatusNotificationName = @"OTRXMPPLoginStatusNotificationName";

NSString *const OTRXMPPOldLoginStatusKey = @"OTRXMPPOldLoginStatusKey";
NSString *const OTRXMPPNewLoginStatusKey = @"OTRXMPPNewLoginStatusKey";
NSString *const OTRXMPPLoginErrorKey = @"OTRXMPPLoginErrorKey";

@implementation OTRXMPPManager

- (instancetype)init
{
    if (self = [super init]) {
        NSString * queueLabel = [NSString stringWithFormat:@"%@.work.%@",[self class],self];
        _workQueue = dispatch_queue_create([queueLabel UTF8String], 0);
        self.connectionStatus = OTRProtocolConnectionStatusDisconnected;
        _buddyTimers = [NSMutableDictionary dictionary];
        _databaseConnection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
    }
    return self;
}

- (instancetype) initWithAccount:(OTRAccount *)newAccount {
    if(self = [self init])
    {
        NSAssert([newAccount isKindOfClass:[OTRXMPPAccount class]], @"Must have XMPP account");
        self.isRegisteringNewAccount = NO;
        _account = (OTRXMPPAccount *)newAccount;
        
        // Setup the XMPP stream
        [self setupStream];        
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

- (OTRXMPPStream*) newStream {
    return [[OTRXMPPStream alloc] init];
}

- (void)setupStream
{
	NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
    
	_xmppStream = [self newStream];

    //Used to fetch correct account from XMPPStream in delegate methods especailly
    self.xmppStream.tag = self.account.uniqueId;
    self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicyRequired;
    
    [self.certificatePinningModule activate:self.xmppStream];
    
    _deliveryReceipts = [[XMPPMessageDeliveryReceipts alloc] init];
    // We want to check if OTR messages can be decrypted
    self.deliveryReceipts.autoSendMessageDeliveryReceipts = NO;
    self.deliveryReceipts.autoSendMessageDeliveryRequests = YES;
    [self.deliveryReceipts activate:self.xmppStream];
	
	// Setup reconnect
	// 
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	_xmppReconnect = [[XMPPReconnect alloc] init];
	
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
	
    _xmppRosterStorage = [[OTRYapDatabaseRosterStorage alloc] init];
	
	_xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
	
	self.xmppRoster.autoFetchRoster = YES;
    self.xmppRoster.autoClearAllUsersAndResources = NO;
	self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	// 
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
    OTRvCardYapDatabaseStorage * vCardStorage  = [[OTRvCardYapDatabaseStorage alloc] init];
	_xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:vCardStorage];
	
	_xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCardTempModule];
	
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
    
    _serverCapabilities = [[OTRServerCapabilities alloc] init];
    [self.serverCapabilities activate:self.xmppStream];
    
    // Add push registration module
    _xmppPushModule = [[XMPPPushModule alloc] init];
    [self.xmppPushModule activate:self.xmppStream];
    [self.xmppPushModule addDelegate:self delegateQueue:self.workQueue];
    
    _xmppCapabilitiesStorage = [[XMPPCapabilitiesCoreDataStorage alloc] initWithInMemoryStore];
    _xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:self.xmppCapabilitiesStorage];
    
    self.xmppCapabilities.autoFetchHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchNonHashedCapabilities = YES;
    self.xmppCapabilities.autoFetchMyServerCapabilities = YES;
    
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
    [self.xmppvCardTempModule addDelegate:self delegateQueue:self.workQueue];
    
    // Message storage
    _messageStorage = [[OTRXMPPMessageYapStorage alloc] initWithDatabaseConnection:self.databaseConnection];
    [self.messageStorage activate:self.xmppStream];
    
    // Message Carbons
    _messageCarbons = [[XMPPMessageCarbons alloc] init];
    [self.messageCarbons addDelegate:self.messageStorage delegateQueue:self.messageStorage.moduleDelegateQueue];
    [self.messageCarbons activate:self.xmppStream];
    
    //Stream Management
    _streamManagementDelegate = [[OTRStreamManagementDelegate alloc] initWithDatabaseConnection:self.databaseConnection];
    
    //OTRStreamManagementYapStorage *streamManagementStorage = [[OTRStreamManagementYapStorage alloc] initWithDatabaseConnection:self.databaseConnection];
    XMPPStreamManagementMemoryStorage *memoryStorage = [[XMPPStreamManagementMemoryStorage alloc] init];
    _streamManagement = [[XMPPStreamManagement alloc] initWithStorage:memoryStorage];
    [self.streamManagement addDelegate:self.streamManagementDelegate delegateQueue:self.workQueue];
    [self.streamManagement automaticallyRequestAcksAfterStanzaCount:10 orTimeout:5];
    [self.streamManagement automaticallySendAcksAfterStanzaCount:30 orTimeout:5];
    self.streamManagement.autoResume = YES;
    [self.streamManagement activate:self.xmppStream];
    
    //MUC
    _roomManager = [[OTRXMPPRoomManager alloc] init];
    self.roomManager.databaseConnection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
    [self.roomManager activate:self.xmppStream];
    
    //Buddy Manager (for deleting)
    _xmppBuddyManager = [[OTRXMPPBuddyManager alloc] init];
    self.xmppBuddyManager.databaseConnection = [OTRDatabaseManager sharedInstance].longLivedReadOnlyConnection;
    self.xmppBuddyManager.protocol = self;
    [self.xmppBuddyManager activate:self.xmppStream];
    
    //Message Queue Module
    MessageQueueHandler *queueHandler = [OTRDatabaseManager sharedInstance].messageQueueHandler;
    _messageStatusModule = [[OTRXMPPMessageStatusModule alloc] initWithDatabaseConnection:self.databaseConnection delegate:queueHandler];
    [self.messageStatusModule activate:self.xmppStream];
    
    //OMEMO
    if ([[OTRAppDelegate appDelegate].theme enableOMEMO]) {
        self.omemoSignalCoordinator = [[OTROMEMOSignalCoordinator alloc] initWithAccountYapKey:self.account.uniqueId databaseConnection:self.databaseConnection error:nil];
        _omemoModule = [[OMEMOModule alloc] initWithOMEMOStorage:self.omemoSignalCoordinator xmlNamespace:OMEMOModuleNamespaceConversationsLegacy];
        [self.omemoModule addDelegate:self.omemoSignalCoordinator delegateQueue:self.workQueue];
        [self.omemoModule activate:self.xmppStream];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushAccountChanged:) name:OTRPushAccountDeviceChanged object:[OTRProtocolManager sharedInstance].pushController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushAccountChanged:) name:OTRPushAccountTokensChanged object:[OTRProtocolManager sharedInstance].pushController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buddyPendingApprovalStateChanged:) name:OTRBuddyPendingApprovalDidChangeNotification object:self.xmppRosterStorage];
    
    _serverCheck = [[ServerCheck alloc] initWithXmpp:self push:[OTRProtocolManager sharedInstance].pushController];
}

- (void)teardownStream
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OTRBuddyPendingApprovalDidChangeNotification object:self.xmppRosterStorage];

    [_xmppStream removeDelegate:self];
    [_xmppRoster removeDelegate:self];
    [_xmppCapabilities removeDelegate:self];
    [_xmppvCardTempModule removeDelegate:self];
    [_xmppPushModule removeDelegate:self];

    [_xmppPushModule deactivate];
    [_xmppReconnect         deactivate];
    [_xmppRoster            deactivate];
    [_xmppvCardTempModule   deactivate];
    [_xmppvCardAvatarModule deactivate];
    [_xmppCapabilities      deactivate];
    [_streamManagement      deactivate];
    [_messageCarbons        deactivate];
    [_messageStorage        deactivate];
    [_certificatePinningModule deactivate];
    [_deliveryReceipts deactivate];
    [_streamManagement deactivate];
    [_roomManager deactivate];
    [_xmppBuddyManager deactivate];
    [_messageStatusModule deactivate];
    [_omemoModule deactivate];
    [_serverCapabilities deactivate];
    _serverCheck = nil;

    [_xmppStream disconnect];
}

- (void) addIdleDate:(NSDate*)date toPresence:(XMPPPresence*)presence {
    // Don't leak any extra info over Tor or non-autologin accounts
    if (self.account.accountType == OTRAccountTypeXMPPTor ||
        !self.account.autologin) {
        return;
    }
    NSString *nowString = [date xmppDateTimeString];
    if (nowString) {
        /*
         <presence from='juliet@capulet.com/balcony'>
         <show>away</show>
         <idle xmlns='urn:xmpp:idle:1' since='1969-07-21T02:56:15Z'/>
         </presence>
         */
        // https://xmpp.org/extensions/xep-0319.html
        NSXMLElement *idle = [NSXMLElement elementWithName:@"idle" xmlns:@"urn:xmpp:idle:1"];
        [idle addAttributeWithName:@"since" stringValue:nowString];
        [presence addChild:idle];
    }
}

/** Sends "away" presence with last idle time */
- (void) goAway {
    // Don't leak any extra info over Tor
    if (self.account.accountType == OTRAccountTypeXMPPTor) {
        return;
    }
    XMPPPresence *presence = [XMPPPresence presence];
    NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"away"];
    [presence addChild:show];
    NSDate *idleDate = [OTRProtocolManager sharedInstance].lastInteractionDate;
    [self addIdleDate:idleDate toPresence:presence];
    [self.xmppStream sendElement:presence];
}

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	[self.xmppStream sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    NSDate *idleDate = [OTRProtocolManager sharedInstance].lastInteractionDate;
    [self addIdleDate:idleDate toPresence:presence]; // I don't think this does anything
	[self.xmppStream sendElement:presence];
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


- (void)authenticateWithStream:(XMPPStream *)stream {
    NSError * error = nil;
    BOOL status = YES;
    if ([stream supportsXOAuth2GoogleAuthentication] && self.account.accountType == OTRAccountTypeGoogleTalk) {
        status = [stream authenticateWithGoogleAccessToken:self.account.password error:&error];
    }
    else {
        status = [stream authenticateWithPassword:self.account.password error:&error];
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

- (BOOL)startConnection
{
    self.connectionStatus = OTRProtocolConnectionStatusConnecting;
    
    XMPPJID *jid = [XMPPJID jidWithString:self.account.username resource:self.account.resource];
    
    if (![jid.domain isEqualToString:self.xmppStream.myJID.domain]) {
        [self.xmppStream disconnect];
    }
    self.xmppStream.myJID = jid;
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

- (void) disconnectSocketOnly:(BOOL)socketOnly {
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, socketOnly);
    if (socketOnly) {
        [self goAway];
        [self.xmppStream disconnectAfterSending];
        self.connectionStatus = OTRProtocolConnectionStatusDisconnected;
        return;
    }
    
    [self goOffline];
    [self.xmppStream disconnectAfterSending];
    
    __weak typeof(self)weakSelf = self;
    __block NSArray<OTRXMPPBuddy*> *buddiesArray = nil;
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        buddiesArray = [strongSelf.account allBuddiesWithTransaction:transaction];
    } completionQueue:dispatch_get_main_queue() completionBlock:^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect])
        {
            [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [OTRBaseMessage deleteAllMessagesForAccountId:strongSelf.account.uniqueId transaction:transaction];
            }];
        }
    }];
}

- (void)disconnect
{
    [self disconnectSocketOnly:NO];
}

- (BOOL)startRegisteringNewAccount
{
    self.isRegisteringNewAccount = YES;
    if (self.xmppStream.isConnected) {
        [self.xmppStream disconnect];
        return NO;
    }
    
    return [self startConnection];
}

- (BOOL)continueRegisteringNewAccount
{
    NSError * error = nil;
    if ([self.xmppStream supportsInBandRegistration]) {
        [self.xmppStream registerWithPassword:self.account.password error:&error];
        if (error) {
            [self failedToRegisterNewAccount:error];
            return NO;
        }
    } else {
        error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPUnsupportedAction userInfo:nil];
        [self failedToRegisterNewAccount:error];
        return NO;
    }
    return YES;
}

#pragma mark Public Methods

/** Will send a probe to fetch last seen */
- (void) sendPresenceProbeForBuddy:(OTRXMPPBuddy*)buddy {
    NSParameterAssert(buddy);
    if (!buddy) { return; }
    XMPPJID *jid = buddy.bareJID;
    if (!jid) { return; }
    
    // We can't probe presence if we are still pending approval, so resend the request.
    if (buddy.pendingApproval) {
        [self.xmppRoster subscribePresenceToUser:jid];
        return;
    }
    
    // https://xmpp.org/extensions/xep-0318.html
    // <presence from='juliet@capulet.com/balcony' to='romeo@montague.com' type='probe' />
    XMPPPresence *probe = [XMPPPresence presenceWithType:@"probe" to:jid];
    if (!probe) { return; }
    [self.xmppStream sendElement:probe];
}

- (void)setAvatar:(UIImage *)avatarImage completion:(void (^)(BOOL success))completion
{
    if (!avatarImage) {
        completion(NO);
        return;
    }
    
    __block UIImage *newImage = avatarImage;
    
    
    dispatch_async(self.workQueue, ^{
        
        //Square crop & Resize image
        newImage = [UIImage otr_prepareForAvatarUpload:newImage maxSize:120.0];
        //jpeg compression
        NSData *data = UIImageJPEGRepresentation(newImage, 0.6);
        
        //Save new avatar right away to update UI
        
        [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            OTRXMPPAccount *account = [[OTRXMPPAccount fetchObjectWithUniqueID:self.account.uniqueId transaction:transaction] copy];
            account.avatarData = data;
            [account saveWithTransaction:transaction];
        }];
        
        self.changeAvatar = [[OTRXMPPChangeAvatar alloc] initWithPhotoData:data
                                                       xmppvCardTempModule:self.xmppvCardTempModule];
        
        __weak typeof(self) weakSelf = self;
        [self.changeAvatar updatePhoto:^(BOOL success) {
            typeof(weakSelf) strongSelf = weakSelf;
            if (completion) {
                completion(success);
            }
            strongSelf.changeAvatar = nil;
        }];
    });
    
}

- (void)changePassword:(NSString *)newPassword completion:(void (^)(BOOL,NSError*))completion {
    if (!completion) {
        return;
    }
    
    if (!self.xmppStream.isAuthenticated || [newPassword length] == 0) {
        completion(NO,nil);
    }
    
    self.changePasswordManager = [[OTRXMPPChangePasswordManager alloc] initWithNewPassword:newPassword xmppStream:self.xmppStream completion:^(BOOL success, NSError * _Nullable error) {
        
        if (success) {
            self.account.password = newPassword;
        }
        self.changePasswordManager = nil;
        completion(success,error);
    }];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [self.changePasswordManager changePassword];
#pragma clang diagnostic pop
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
        [self continueRegisteringNewAccount];
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
    __block NSArray<OTRXMPPBuddy*> *allBuddies = nil;
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        allBuddies = [self.account allBuddiesWithTransaction:transaction];
    } completionBlock:^{
        // We don't need to save in here because we're using OTRBuddyCache in memory storage
        if (!self.streamManagementDelegate.streamManagementEnabled) {
            [[OTRBuddyCache sharedInstance] purgeAllPropertiesForBuddies:allBuddies];
        }
    }];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if ([sender supportsStreamManagement] && ![self.streamManagement didResume]) {
        [self.streamManagement enableStreamManagementWithResumption:YES maxTimeout:0];
    }
    
    self.connectionStatus = OTRProtocolConnectionStatusConnected;
    NSString *accountKey = self.account.uniqueId;
    NSString *accountCollection = [[self.account class] collection];
    NSDictionary *userInfo = nil;
    if(accountKey && accountCollection) {
        userInfo = @{kOTRNotificationAccountUniqueIdKey:accountKey,kOTRNotificationAccountCollectionKey:accountCollection};
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolLoginSuccess
     object:self userInfo:userInfo];
    
    [self changeLoginStatus:OTRLoginStatusAuthenticated error:nil];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [self goOnline];
    } else {
        [self goAway];
    }
    
    // Fetch latest vCard from server so we can update nickname
    //[self.xmppvCardTempModule fetchvCardTempForJID:self.JID ignoreStorage:YES];
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
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, iq);
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
	DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, xmppMessage);
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@\n%@", THIS_FILE, THIS_METHOD, presence.prettyXMLString);
    
    
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error
{
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, iq, error);
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, message, error);
    if (![message.elementID length]) {
        return;
    }
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction enumerateMessagesWithId:message.elementID block:^(id<OTRMessageProtocol> _Nonnull databaseMessage, BOOL * _Null_unspecified stop) {
            if ([databaseMessage isKindOfClass:[OTRBaseMessage class]]) {
                ((OTRBaseMessage *)databaseMessage).error = error;
                [(OTRBaseMessage *)databaseMessage saveWithTransaction:transaction];
                *stop = YES;
            }
        }];
    }];
}
- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error
{
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, presence, error);
}

#pragma mark XMPPvCardTempModuleDelegate

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule
        didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp
                     forJID:(XMPPJID *)jid {
    DDLogVerbose(@"%@: %@ %@ %@ %@", THIS_FILE, THIS_METHOD, vCardTempModule, vCardTemp, jid);
    
    // update my vCard to local nickname setting
    // currently this will clobber whatever you have on the server
    if ([self.xmppStream.myJID isEqualToJID:jid options:XMPPJIDCompareBare]) {
        if (self.account.displayName.length &&
            vCardTemp.nickname.length &&
            ![vCardTemp.nickname isEqualToString:self.account.displayName]) {
            vCardTemp.nickname = self.account.displayName;
            [vCardTempModule updateMyvCardTemp:vCardTemp];
        } else if (vCardTemp.nickname.length) {
            [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                NSString *collection = [self.account.class collection];
                NSString *key = self.account.uniqueId;
                OTRXMPPAccount *account = [[transaction objectForKey:key inCollection:collection] copy];
                account.displayName = vCardTemp.nickname;
                [transaction setObject:account forKey:key inCollection:collection];
            }];
        }
    } else {
        // this is someone elses vCard
        DDLogVerbose(@"%@: other's vCard %@ %@ %@ %@", THIS_FILE, THIS_METHOD, vCardTempModule, vCardTemp, jid);
    }
}

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule
   failedToFetchvCardForJID:(XMPPJID *)jid
                      error:(NSXMLElement*)error {
    DDLogVerbose(@"%@: %@ %@ %@ %@", THIS_FILE, THIS_METHOD, vCardTempModule, jid, error);
    
    // update my vCard to local nickname setting
    if ([self.xmppStream.myJID isEqualToJID:jid options:XMPPJIDCompareBare] &&
        self.account.displayName.length) {
        XMPPvCardTemp *vCardTemp = [XMPPvCardTemp vCardTemp];
        vCardTemp.nickname = self.account.displayName;
        [vCardTempModule updateMyvCardTemp:vCardTemp];
    }
}

- (void)xmppvCardTempModuleDidUpdateMyvCard:(XMPPvCardTempModule *)vCardTempModule {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, vCardTempModule);
}

- (void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule failedToUpdateMyvCard:(NSXMLElement *)error {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, vCardTempModule, error);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, item);

    // Because XMPP sucks, there's no way to know if a vCard has changed without fetching all of them again
    // To preserve user mobile data, just fetch each vCard once, only if it's never been fetched
    // Otherwise you'll only receive vCard updates if someone updates their avatar
    NSString *jidStr = [item attributeStringValueForName:@"jid"];
    XMPPJID *jid = [[XMPPJID jidWithString:jidStr] bareJID];
    __block OTRXMPPBuddy *buddy = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        buddy = [OTRXMPPBuddy fetchBuddyWithUsername:[jid bare] withAccountUniqueId:self.account.uniqueId transaction:transaction];
    } completionQueue:self.workQueue completionBlock:^{
        if (!buddy) { return; }
        XMPPvCardTemp *vCard = [self.xmppvCardTempModule vCardTempForJID:jid shouldFetch:YES];
        if (!vCard) { return; }
        [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            buddy = [[OTRXMPPBuddy fetchBuddyWithUsername:[jid bare] withAccountUniqueId:self.account.uniqueId transaction:transaction] copy];
            if (!buddy) { return; }
            buddy.vCardTemp = vCard;
            [buddy saveWithTransaction:transaction];
        }];
    }];
}

-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, presence);
    
	NSString *jidStrBare = [presence fromStr];
    
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRXMPPPresenceSubscriptionRequest *request = [OTRXMPPPresenceSubscriptionRequest fetchPresenceSubscriptionRequestWithJID:jidStrBare accontUniqueId:self.account.uniqueId transaction:transaction];
        if (!request) {
            request = [[OTRXMPPPresenceSubscriptionRequest alloc] init];
            [[UIApplication sharedApplication] showLocalNotificationForSubscriptionRequestFrom:jidStrBare];
        }
        
        request.jid = jidStrBare;
        request.accountUniqueId = self.account.uniqueId;
        
        [request saveWithTransaction:transaction];
    }];
}

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, iq);
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

#pragma mark XMPPPushDelegate

- (void) pushAccountChanged:(NSNotification*)notif {
    __block OTRXMPPAccount *account = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        NSString *collection = [self.account.class collection];
        NSString *key = self.account.uniqueId;
        account = [transaction objectForKey:key inCollection:collection];
    }];
    if (!account.pushPubsubEndpoint) { return; }
    XMPPJID *serverJID = [XMPPJID jidWithUser:nil domain:account.pushPubsubEndpoint resource:nil];
    if (!serverJID) { return; }
    XMPPPushStatus status = [self.xmppPushModule registrationStatusForServerJID:serverJID];
    if (status != XMPPPushStatusRegistered &&
        status != XMPPPushStatusRegistering) {
        [self.xmppPushModule refresh];
    }
}

- (void)pushModule:(XMPPPushModule*)module readyWithCapabilities:(NSXMLElement *)caps jid:(XMPPJID *)jid {
    // Enable XEP-0357 push bridge if server supports it
    // ..but don't register for Tor accounts
    if (self.account.accountType == OTRAccountTypeXMPPTor) {
        return;
    }
    BOOL hasPushAccount = [[OTRProtocolManager sharedInstance].pushController.pushStorage hasPushAccount];
    if (!hasPushAccount) {
        return;
    }
    [[OTRProtocolManager sharedInstance].pushController getPubsubEndpoint:^(NSString * _Nullable endpoint, NSError * _Nullable error) {
        if (endpoint) {
            [[OTRProtocolManager sharedInstance].pushController getNewPushToken:nil completion:^(TokenContainer * _Nullable token, NSError * _Nullable error) {
                if (token) {
                    [self enablePushWithToken:token endpoint:endpoint];
                } else if (error) {
                    DDLogError(@"fetch token error: %@", error);
                }
            }];
        } else if (error) {
            DDLogError(@"357 pubsub Error: %@", error);
        }
    }];
}

- (void) enablePushWithToken:(TokenContainer*)token endpoint:(NSString*)endpoint {
    __block OTRXMPPAccount *account = nil;
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        NSString *collection = [self.account.class collection];
        NSString *key = self.account.uniqueId;
        account = [[transaction objectForKey:key inCollection:collection] copy];
        account.pushPubsubEndpoint = endpoint;
        if (!account.pushPubsubNode.length) {
            account.pushPubsubNode = [[NSUUID UUID] UUIDString];
        }
        [transaction setObject:account forKey:key inCollection:collection];
    }];
    XMPPJID *nodeJID = [XMPPJID jidWithString:endpoint];
    NSString *tokenString = token.pushToken.tokenString;
    if (tokenString.length > 0) {
        NSString *pushEndpointURLString = [[OTRProtocolManager sharedInstance].pushController getMessagesEndpoint].absoluteString;
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:tokenString forKey:@"token"];
        if (pushEndpointURLString) {
            [options setObject:pushEndpointURLString forKey:@"endpoint"];
        }
        XMPPPushOptions *pushOptions = [[XMPPPushOptions alloc] initWithServerJID:nodeJID node:account.pushPubsubNode formOptions:options];
        [self.xmppPushModule registerForPushWithOptions:pushOptions elementId:nil];
    }
}

- (void)pushModule:(XMPPPushModule*)module
didRegisterWithResponseIq:(XMPPIQ*)responseIq
        outgoingIq:(XMPPIQ*)outgoingIq {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, responseIq, outgoingIq);
}

- (void)pushModule:(XMPPPushModule*)module
failedToRegisterWithErrorIq:(nullable XMPPIQ*)errorIq
        outgoingIq:(XMPPIQ*)outgoingIq {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, errorIq, outgoingIq);
}

- (void)pushModule:(XMPPPushModule*)module
disabledPushForServerJID:(XMPPJID*)serverJID
              node:(nullable NSString*)node
        responseIq:(XMPPIQ*)responseIq
        outgoingIq:(XMPPIQ*)outgoingIq {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, responseIq, outgoingIq);
}

- (void)pushModule:(XMPPPushModule*)module
failedToDisablePushWithErrorIq:(nullable XMPPIQ*)errorIq
         serverJID:(XMPPJID*)serverJID
              node:(nullable NSString*)node
        outgoingIq:(XMPPIQ*)outgoingIq {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, errorIq, outgoingIq);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OTRProtocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendMessage:(OTROutgoingMessage*)message
{
    NSString *text = message.text;
    
    __block OTRBuddy *buddy = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = (OTRBuddy *)[message threadOwnerWithTransaction:transaction];
    }];
    
    [self invalidatePausedChatStateTimerForBuddyUniqueId:buddy.uniqueId];
    
    if ([text length])
    {
        NSString * messageID = message.messageId;
        XMPPMessage * xmppMessage = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:buddy.username] elementID:messageID];
        [xmppMessage addBody:text];

        [xmppMessage addActiveChatState];
        
        if ([OTRKit stringStartsWithOTRPrefix:text]) {
            [xmppMessage addPrivateMessageCarbons];
            [xmppMessage addStorageHint:XMPPMessageStorageNoCopy];
            [xmppMessage addStorageHint:XMPPMessageStorageNoPermanentStore];
        }
		
		[self.xmppStream sendElement:xmppMessage];
    }
}

- (NSString*) type {
    return kOTRProtocolTypeXMPP;
}

- (void) connectUserInitiated:(BOOL)userInitiated
{
    self.userInitiatedConnection = userInitiated;
    // Don't issue a reconnect if we're already connected and authenticated
    if ([self.xmppStream isConnected] && [self.xmppStream isAuthenticated]) {
        XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
        [[self xmppStream] sendElement:presence];
        return;
    }
    [self startConnection];
    if (self.userInitiatedConnection) {
        [[OTRNotificationController sharedInstance] showAccountConnectingNotificationWithAccountName:self.account.username];
    }
}

-(void)connect
{
    [self connectUserInitiated:NO];
}

-(void)sendChatState:(OTRChatState)chatState withBuddyID:(NSString *)buddyUniqueId
{
    dispatch_async(self.workQueue, ^{
        
        __block OTRXMPPBuddy *buddy = nil;
        [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [OTRXMPPBuddy fetchObjectWithUniqueID:buddyUniqueId transaction:transaction];
        }];
        if (!buddy) { return; }
        
        if (buddy.lastSentChatState == chatState) {
            return;
        }
        
        XMPPMessage * xMessage = [[XMPPMessage alloc] initWithType:@"chat" to:[XMPPJID jidWithString:buddy.username]];
        BOOL shouldSend = YES;
        
        if (chatState == OTRChatStateActive) {
            //Timers
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self pausedChatStateTimerForBuddyObjectID:buddyUniqueId] invalidate];
                [self restartInactiveChatStateTimerForBuddyObjectID:buddyUniqueId];
            });
            
            [xMessage addActiveChatState];
        }
        else if (chatState == OTRChatStateComposing)
        {
            if(buddy.lastSentChatState !=OTRChatStateComposing)
                [xMessage addComposingChatState];
            else
                shouldSend = NO;
            
            //Timers
            dispatch_async(dispatch_get_main_queue(), ^{
                [self restartPausedChatStateTimerForBuddyObjectID:buddy.uniqueId];
                [[self inactiveChatStateTimerForBuddyObjectID:buddy.uniqueId] invalidate];
            });
        }
        else if(chatState == OTRChatStateInactive)
        {
            if(buddy.lastSentChatState != OTRChatStateInactive)
                [xMessage addInactiveChatState];
            else
                shouldSend = NO;
        }
        else if (chatState == OTRChatStatePaused)
        {
            [xMessage addPausedChatState];
        }
        else if (chatState == OTRChatStateGone)
        {
            [xMessage addGoneChatState];
        }
        else
        {
            shouldSend = NO;
        }
        
        if(shouldSend)
        {
            [[OTRBuddyCache sharedInstance] setLastSentChatState:chatState forBuddy:buddy];
            [self.xmppStream sendElement:xMessage];
        }
    });
}

- (void) addBuddy:(OTRXMPPBuddy *)newBuddy
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRYapAddBuddyAction *addBuddyAction = [[OTRYapAddBuddyAction alloc] init];
        addBuddyAction.buddyKey = newBuddy.uniqueId;
        [addBuddyAction saveWithTransaction:transaction];
    }];
}

- (void) setDisplayName:(NSString *) newDisplayName forBuddy:(OTRXMPPBuddy *)buddy
{
    XMPPJID * jid = [XMPPJID jidWithString:buddy.username];
    [self.xmppRoster setNickname:newDisplayName forUser:jid];
    
}
-(void)removeBuddies:(NSArray *)buddies
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        // Add actions to the queue
        for (OTRXMPPBuddy *buddy in buddies){
            OTRYapRemoveBuddyAction *removeBuddyAction = [[OTRYapRemoveBuddyAction alloc] init];
            removeBuddyAction.buddyKey = buddy.uniqueId;
            removeBuddyAction.buddyJid = buddy.username;
            removeBuddyAction.accountKey = buddy.accountUniqueId;
            [removeBuddyAction saveWithTransaction:transaction];
        }
        
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

-(OTRXMPPBuddyTimers *)buddyTimersForBuddyObjectID:(NSString *)
managedBuddyObjectID
{
    OTRXMPPBuddyTimers * timers = [self.buddyTimers objectForKey:managedBuddyObjectID];
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
        OTRXMPPBuddyTimers * timer = [self.buddyTimers objectForKey:managedBuddyObjectID];
        if(!timer)
        {
            timer = [[OTRXMPPBuddyTimers alloc] init];
        }
        [timer.pausedChatStateTimer invalidate];
        timer.pausedChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStatePausedTimeout target:self selector:@selector(sendPausedChatState:) userInfo:managedBuddyObjectID repeats:NO];
        [self.buddyTimers setObject:timer forKey:managedBuddyObjectID];
    });
    
}
-(void)restartInactiveChatStateTimerForBuddyObjectID:(NSString *)managedBuddyObjectID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OTRXMPPBuddyTimers * timer = [self.buddyTimers objectForKey:managedBuddyObjectID];
        if(!timer)
        {
            timer = [[OTRXMPPBuddyTimers alloc] init];
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
    [self sendChatState:OTRChatStatePaused withBuddyID:managedBuddyObjectID];
}
-(void)sendInactiveChatState:(NSTimer *)timer
{
    NSString *managedBuddyObjectID= (NSString *)timer.userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        [timer invalidate];
    });
    
    [self sendChatState:OTRChatStateInactive withBuddyID:managedBuddyObjectID];
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

// Delivery receipts
- (void) sendDeliveryReceiptForMessage:(OTRIncomingMessage*)message {
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:message.buddyUniqueId transaction:transaction];        
        XMPPMessage *tempMessage = [XMPPMessage messageWithType:@"chat" elementID:message.messageId];
        [tempMessage addAttributeWithName:@"from" stringValue:buddy.username];
        XMPPMessage *receiptMessage = [tempMessage generateReceiptResponse];
        [self.xmppStream sendElement:receiptMessage];
    }];
}

// A new buddy has approved us, show a local notification
- (void) buddyPendingApprovalStateChanged:(NSNotification*)notif {
    if (notif != nil && notif.userInfo != nil) {
        OTRBuddy *buddy = [notif.userInfo objectForKey:@"buddy"];
        if (buddy != nil) {
            [[UIApplication sharedApplication] showLocalNotificationForApprovedBuddy:buddy];
        }
    }
}

@end
