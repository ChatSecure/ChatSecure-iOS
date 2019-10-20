//
//  OTRXMPPManager_Private.h
//  ChatSecure
//
//  Created by Chris Ballinger on 11/5/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPManager.h"
#import "OTRCertificatePinning.h"
#import "OTRXMPPBuddyManager.h"
#import "ChatSecureCoreCompat-Swift.h"
#import "OTRXMPPRoomManager.h"
#import "OTRXMPPBuddyTimers.h"
@import XMPPFramework;

NS_ASSUME_NONNULL_BEGIN
@interface OTRXMPPManager() <OTRCertificatePinningDelegate>

@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) RosterStorage * xmppRosterStorage;
@property (nonatomic, strong) OTRCertificatePinning * certificatePinningModule;

@property (nonatomic, strong, readonly) XMPPStreamManagement *streamManagement;

@property (nonatomic, strong, readonly) OTRXMPPBuddyManager* xmppBuddyManager;
@property (nonatomic, strong, readonly) OMEMOModule *omemoModule;
@property (nonatomic, strong, nullable) OTRXMPPChangePasswordManager *changePasswordManager;

@property (nonatomic, strong, readonly) XMPPMessageDeliveryReceipts *deliveryReceipts;
@property (nonatomic, strong, readonly) OTRXMPPMessageStatusModule *messageStatusModule;
@property (nonatomic, strong, readonly) OTRStreamManagementDelegate *streamManagementDelegate;
@property (nonatomic, strong, readonly) XMPPStanzaIdModule *stanzaIdModule;
/// This is a readwrite connection
@property (nonatomic, strong, readonly) YapDatabaseConnection *databaseConnection;

@property (nonatomic, strong, readonly) dispatch_queue_t workQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,OTRXMPPBuddyTimers*> * buddyTimers;

@property (nonatomic, strong, nullable) OTRXMPPChangeAvatar *changeAvatar;

@property (nonatomic, readwrite) BOOL isRegisteringNewAccount;
@property (nonatomic, readwrite) BOOL userInitiatedConnection;
@property (atomic, readwrite) OTRLoginStatus loginStatus;

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;
- (void)failedToConnect:(NSError *)error;

/** wtf. why isn't this being picked up by OTRProtocol */
- (void) connectUserInitiated:(BOOL)userInitiated;

/** Return a newly allocated stream object. This is overridden in OTRXMPPTorManager to use ProxyXMPPStream instead of XMPPStream */
- (XMPPStream*) newStream;

@end
NS_ASSUME_NONNULL_END
