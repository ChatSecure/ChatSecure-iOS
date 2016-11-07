//
//  OTRXMPPManager_Private.h
//  ChatSecure
//
//  Created by Chris Ballinger on 11/5/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPManager.h"
#import "OTRCertificatePinning.h"
#import "OTRXMPPMessageYapStroage.h"
#import "OTRXMPPBuddyManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRYapDatabaseRosterStorage.h"
#import "OTRXMPPRoomManager.h"

@interface OTRXMPPManager() <OTRCertificatePinningDelegate>
@property (nonatomic) OTRProtocolConnectionStatus connectionStatus;
@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) OTRYapDatabaseRosterStorage * xmppRosterStorage;
@property (nonatomic, strong) OTRCertificatePinning * certificatePinningModule;
@property (nonatomic, strong) NSMutableDictionary * buddyTimers;
@property (nonatomic) dispatch_queue_t workQueue;
@property (nonatomic) BOOL isRegisteringNewAccount;
@property (nonatomic, strong) XMPPStreamManagement *streamManagement;
@property (nonatomic, strong) XMPPMessageCarbons *messageCarbons;
@property (nonatomic, strong) OTRXMPPMessageYapStroage *messageStorage;
@property (nonatomic) BOOL userInitiatedConnection;
@property (nonatomic) OTRLoginStatus loginStatus;
@property (nonatomic, strong) OTRXMPPBuddyManager* xmppBuddyManager;

@property (nonatomic, strong) OMEMOModule *omemoModule;


@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) XMPPMessageDeliveryReceipts *deliveryReceipts;
@property (nonatomic, strong) OTRXMPPMessageStatusModule *messageStatusModule;
@property (nonatomic, strong) OTRStreamManagementDelegate *streamManagementDelegate;

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;
- (void)failedToConnect:(NSError *)error;



/** wtf. why isn't this being picked up by OTRProtocol */
- (void) connectUserInitiated:(BOOL)userInitiated;

@end
