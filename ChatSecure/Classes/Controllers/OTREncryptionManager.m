//
//  OTREncryptionManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
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

#import "OTREncryptionManager.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"
#import "OTRUtilities.h"
@import OTRAssets;
#import "OTRAppDelegate.h"
#import "OTRMessagesHoldTalkViewController.h"
#import "UIViewController+ChatSecure.h"
#import "OTRImageItem.h"
#import "OTRAudioItem.h"
#import "OTRVideoItem.h"
#import "OTRMediaFileManager.h"
#import "OTRMediaServer.h"
#import "OTRDatabaseManager.h"
#import "OTRLog.h"
#import "OTRXMPPManager.h"
#import "OTRYapMessageSendAction.h"
#import "ChatSecureCoreCompat-Swift.h"

@import AVFoundation;
@import XMPPFramework;
@import OTRAssets;

NSString *const OTRMessageStateDidChangeNotification = @"OTREncryptionManagerMessageStateDidChangeNotification";
NSString *const OTRWillStartGeneratingPrivateKeyNotification = @"OTREncryptionManagerWillStartGeneratingPrivateKeyNotification";
NSString *const OTRDidFinishGeneratingPrivateKeyNotification = @"OTREncryptionManagerdidFinishGeneratingPrivateKeyNotification";
NSString *const OTRMessageStateKey = @"OTREncryptionManagerMessageStateKey";

@interface OTREncryptionManager () <OTRKitDelegate, OTRDataHandlerDelegate>
@property (nonatomic, strong) OTRKit *otrKit;
@property (nonatomic, strong) NSCache *otrFingerprintCache;
@property (nonatomic, readonly) YapDatabaseConnection *readConnection;
@end

@implementation OTREncryptionManager


- (id) init {
    if (self = [super init]) {
        _otrFingerprintCache = [[NSCache alloc] init];
        _otrKit = [[OTRKit alloc] initWithDelegate:self dataPath:nil];
        _dataHandler = [[OTRDataHandler alloc] initWithOTRKit:self.otrKit delegate:self];
        _readConnection = OTRDatabaseManager.shared.readConnection;
        NSArray *protectPaths = @[self.otrKit.privateKeyPath, self.otrKit.fingerprintsPath, self.otrKit.instanceTagsPath];
        for (NSString *path in protectPaths) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [@"" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            [OTREncryptionManager setFileProtection:NSFileProtectionCompleteUntilFirstUserAuthentication path:path];
            [OTREncryptionManager addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:path]];
        }
        self.otrKit.otrPolicy = OTRKitPolicyOpportunistic;
    }
    return self;
}

- (OTRProtocolType)prototcolTypeForString:(NSString *)typeString
{
    if ([typeString isEqualToString:kOTRProtocolTypeXMPP])
    {
        return OTRProtocolTypeXMPP;
    }
    else {
        return OTRProtocolTypeNone;
    }
}

- (void)maybeRefreshOTRSessionForBuddyKey:(NSString *)buddyKey collection:(NSString *)collection {
    __block OTRBuddy *buddy = nil;
    __block OTRAccount *account = nil;
    __block BOOL hasOMEMODevices = NO;
    [self.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        id databaseObject = [transaction objectForKey:buddyKey inCollection:collection];
        if ([databaseObject isKindOfClass:[OTRBuddy class]]) {
            buddy = databaseObject;
            account = [buddy accountWithTransaction:transaction];
        }
        hasOMEMODevices = [OMEMODevice allDevicesForParentKey:buddyKey collection:collection transaction:transaction].count > 0;
    } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionBlock:^{
        
        if (buddy == nil || account == nil) {
            return;
        }
        
        if (buddy.currentStatus == OTRThreadStatusOffline) {
            //If the buddy if offline then don't try to start the session up
            return;
        }
        
        // Exit if OTRSessionSecurity is not set to use OTR
        if (buddy.preferredSecurity != OTRSessionSecurityOTR) {
            return;
        }
        
        NSArray<OTRFingerprint *>*fingerprints = [self.otrKit fingerprintsForUsername:buddy.username accountName:account.username protocol:account.protocolTypeString];
        if ([fingerprints count] > 0 || hasOMEMODevices) {
            OTRKitMessageState messageState = [self.otrKit messageStateForUsername:buddy.username accountName:account.username protocol:account.protocolTypeString];
            if (messageState != OTRKitMessageStateEncrypted) {
                [self.otrKit initiateEncryptionWithUsername:buddy.username accountName:account.username protocol:account.protocolTypeString];
            }
        }
    }];
}

- (NSString *)cacheKeyForYapKey:(NSString *)key collection:(NSString *)collection fingerprint:(NSData *)data
{
    return [NSString stringWithFormat:@"%@%@%@",key,collection,@([data hash])];
}

- (OTRTrustLevel)otrFetchTrustForUsername:(NSString*)username
                              accountName:(NSString*)accountName
                                 protocol:(NSString*)protocol
                              fingerprint:(NSData *)fingerprintData
{
    NSArray<OTRFingerprint*>*fingerprints = [self.otrKit fingerprintsForUsername:username accountName:accountName protocol:protocol];
    __block OTRTrustLevel trust = OTRTrustLevelUnknown;
    [fingerprints enumerateObjectsUsingBlock:^(OTRFingerprint * _Nonnull finger, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([finger.fingerprint isEqualToData:fingerprintData]) {
            trust = finger.trustLevel;
            *stop = YES;
        }
    }];
    
    return trust;
}

- (OTRFingerprint *)otrFingerprintForKey:(NSString *)key collection:(NSString *)collection fingerprint:(NSData *)fingerprint;
{
    NSString *cacheKey = [self cacheKeyForYapKey:key collection:collection fingerprint:fingerprint];
    NSNumber *resultNumber = [self.otrFingerprintCache objectForKey:cacheKey];
    OTRTrustLevel trust = OTRTrustLevelUnknown;
    __block OTRBuddy *buddy = nil;
    __block OTRAccount *account = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        buddy = [transaction objectForKey:key inCollection:collection];
        account = [buddy accountWithTransaction:transaction];
    }];
    
    if (!buddy || !account) {
        return nil;
    }
    
    if (resultNumber == nil) {
        trust = [self otrFetchTrustForUsername:buddy.username accountName:account.username protocol:account.protocolTypeString fingerprint:fingerprint];
        // No point in saving uknown trust to the cache. This might cause issues with the cach not being invalidated properly.
        if (trust != OTRTrustLevelUnknown) {
            [self.otrFingerprintCache setObject:@(trust) forKey:cacheKey];
        }
        
    } else {
        trust = resultNumber.unsignedIntegerValue;
    }
    
    return [[OTRFingerprint alloc] initWithUsername:buddy.username accountName:account.username protocol:account.protocolTypeString fingerprint:fingerprint trustLevel:trust];
}

- (void)saveFingerprint:(OTRFingerprint *)fingerprint;
{
    __block OTRBuddy *buddy = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        buddy = [self buddyForFingerprint:fingerprint transaction:transaction];
    }];
    [self.otrFingerprintCache setObject:@(fingerprint.trustLevel) forKey:[self cacheKeyForYapKey:buddy.uniqueId collection:[buddy.class collection] fingerprint:fingerprint.fingerprint]];
    
    [self.otrKit saveFingerprint:fingerprint];
}

- (BOOL)removeOTRFingerprint:(OTRFingerprint *)fingerprint error:( NSError * _Nullable *)error;
{
    __block OTRXMPPBuddy *buddy = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        buddy = [self buddyForFingerprint:fingerprint transaction:transaction];
    }];
    
    if (!buddy) {
        return false;
    }
    
    NSString *cacheKey = [self cacheKeyForYapKey:buddy.uniqueId collection:[buddy.class collection] fingerprint:fingerprint.fingerprint];
    [self.otrFingerprintCache removeObjectForKey:cacheKey];
    
    return [self.otrKit deleteFingerprint:fingerprint error:error];
}

- (nullable OTRXMPPBuddy*) buddyForFingerprint:(OTRFingerprint*)fingerprint transaction:(YapDatabaseReadTransaction*)transaction {
    return [self buddyForUsername:fingerprint.username accountName:fingerprint.accountName transaction:transaction];
}

- (nullable OTRXMPPBuddy*) buddyForUsername:(NSString*)username accountName:(NSString*)accountName transaction:(YapDatabaseReadTransaction*)transaction {
    XMPPJID *jid = [XMPPJID jidWithString:username];
    if (!jid) {
        DDLogWarn(@"OTRKitDelegate: not a valid JID: %@ %@", username, accountName);
        return nil;
    }
    OTRAccount *account = [OTRAccount allAccountsWithUsername:accountName transaction:transaction].firstObject;
    if (!account) {
        DDLogWarn(@"OTRKitDelegate: Account not found for %@ %@", username, accountName);
        return nil;
    }
    OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyWithJid:jid accountUniqueId:account.uniqueId transaction:transaction];
    if (!buddy) {
        DDLogWarn(@"OTRKitDelegate: Buddy not found for %@ %@", username, accountName);
        return nil;
    }
    return buddy;
}


#pragma mark OTRKitDelegate methods

- (void)otrKit:(OTRKit *)otrKit injectMessage:(NSString *)text username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol fingerprint:(OTRFingerprint *)fingerprint tag:(id)tag
{
    //only otrproltocol
    OTROutgoingMessage *message = [[OTROutgoingMessage alloc] init];
    message.text =text;
    
    __block OTRBuddy *buddy = nil;
    [self.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [self buddyForUsername:username accountName:accountName transaction:transaction];
    } completionBlock:^{
        if (!buddy) { return; }
        message.buddyUniqueId = buddy.uniqueId;
        [[OTRProtocolManager sharedInstance] sendMessage:message];
    }];
}
    
- (void)otrKit:(OTRKit *)otrKit encodedMessage:(NSString *)encodedMessage wasEncrypted:(BOOL)wasEncrypted username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol fingerprint:(OTRFingerprint *)fingerprint tag:(id)tag error:(NSError *)error
{
    if (error) {
        DDLogError(@"Encode Error: %@",error);
    }
    
    
    //
    if ([tag isKindOfClass:[OTRBaseMessage class]]) {
        OTRBaseMessage *message = nil;
        message = [tag copy];
        
        // When replying to OTRDATA requests, we pass along the tag
        // of the original incoming message. We don't want to actually show these messages in the chat
        // so if we detect an incoming message in the encodedMessage callback we should just send the encoded data.
        if ([message isKindOfClass:[OTRIncomingMessage class]]) {
            OTROutgoingMessage *otrDataMessage = [[OTROutgoingMessage alloc] init];
            otrDataMessage.buddyUniqueId = message.buddyUniqueId;
            otrDataMessage.text = encodedMessage;
            [[OTRProtocolManager sharedInstance] sendMessage:otrDataMessage];
            return;
        } else if ([message isKindOfClass:[OTROutgoingMessage class]]) {
            OTROutgoingMessage *outgoingMessage = (OTROutgoingMessage *)message;
            if (error) {
                [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    OTROutgoingMessage *dbMessage = [[transaction objectForKey:outgoingMessage.uniqueId inCollection:[OTROutgoingMessage collection]] copy];
                    dbMessage.error = error;
                    [dbMessage saveWithTransaction:transaction];
                    // Need to make sure any sending action associated with this message is removed
                    NSString * actionKey = [OTRYapMessageSendAction actionKeyForMessageKey:dbMessage.uniqueId messageCollection:[OTROutgoingMessage collection]];
                    [transaction removeObjectForKey:actionKey inCollection:[OTRYapMessageSendAction collection]];
                }];
            }
            else if ([encodedMessage length]) {
                if (wasEncrypted && fingerprint != nil) {
                    outgoingMessage.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithOTRFingerprint:fingerprint.fingerprint];
                }
                [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [message saveWithTransaction:transaction];
                } completionBlock:^{
                    OTROutgoingMessage *newEncodedMessage = [outgoingMessage copy];
                    newEncodedMessage.text = encodedMessage;
                    [[OTRProtocolManager sharedInstance] sendMessage:newEncodedMessage];
                }];
            }
        }
        
        
    }
    else if ([encodedMessage length]) {
        __block OTROutgoingMessage *outgoingMessage = nil;
        [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            outgoingMessage = [[OTROutgoingMessage alloc] init];
            outgoingMessage.text = encodedMessage;
            OTRBuddy *buddy = [self buddyForUsername:username accountName:accountName transaction:transaction];
            outgoingMessage.buddyUniqueId = buddy.uniqueId;
            
        } completionBlock:^{
            [[OTRProtocolManager sharedInstance] sendMessage:outgoingMessage];
        }];
    }
}

- (void)otrKit:(OTRKit *)otrKit decodedMessage:(NSString *)decodedMessage tlvs:(NSArray<OTRTLV *> *)tlvs wasEncrypted:(BOOL)wasEncrypted username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol fingerprint:(OTRFingerprint *)fingerprint tag:(id)tag error:(NSError *)error
{
    //decodedMessage can be nil if just TLV
    OTRIncomingMessage *originalMessage = nil;
    if ([tag isKindOfClass:[OTRIncomingMessage class]]) {
        originalMessage = [tag copy];
    }
    NSParameterAssert(originalMessage);
    
    decodedMessage = [OTRUtilities stripHTML:decodedMessage];
    decodedMessage = [decodedMessage stringByTrimmingCharactersInSet:
     [NSCharacterSet whitespaceCharacterSet]];
    
    if ([decodedMessage length]) {
        originalMessage.text = decodedMessage;
        
        if (wasEncrypted) {
            originalMessage.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithOTRFingerprint:fingerprint.fingerprint];
        }
        __block OTRXMPPManager *xmpp = nil;
        __block OTRAccount *account = nil;
        [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [originalMessage saveWithTransaction:transaction];
            //Update lastMessageDate for sorting and grouping
            OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:originalMessage.buddyUniqueId transaction:transaction];
            buddy.lastMessageId = originalMessage.uniqueId;
            [buddy saveWithTransaction:transaction];
            
            // Send delivery receipt
            account = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction];
            xmpp = (OTRXMPPManager*) [[OTRProtocolManager sharedInstance] protocolForAccount:account];
            [xmpp sendDeliveryReceiptForMessage:originalMessage];
            
            [xmpp.fileTransferManager createAndDownloadItemsIfNeededWithMessage:originalMessage force:NO transaction:transaction];
            [[UIApplication sharedApplication] showLocalNotification:originalMessage transaction:transaction];
        }];
    }
    
    if ([tlvs count]) {
        //DDLogVerbose(@"Found TLVS: %@",tlvs);
    }
}

- (void)otrKit:(OTRKit *)otrKit updateMessageState:(OTRKitMessageState)messageState username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol fingerprint:(OTRFingerprint *)fingerprint
{
    __block OTRBuddy *buddy = nil;
    [self.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [self buddyForUsername:username accountName:accountName transaction:transaction];
    } completionBlock:^{
        if(!buddy) {
            // We couldn't find the budy. This is very strange and shouldn't happen.
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:OTRMessageStateDidChangeNotification object:buddy userInfo:@{OTRMessageStateKey:@([[self class] convertEncryptionState:messageState])}];
    }];
}

- (BOOL)       otrKit:(OTRKit*)otrKit
   isUsernameLoggedIn:(NSString*)username
          accountName:(NSString*)accountName
             protocol:(NSString*)protocol {
    
    __block OTRBuddy *buddy = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [self buddyForUsername:username accountName:accountName transaction:transaction];
    }];
    
    if(!buddy || buddy.currentStatus == OTRThreadStatusOffline) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void)                           otrKit:(OTRKit*)otrKit
  showFingerprintConfirmationForTheirHash:(NSString*)theirHash
                                  ourHash:(NSString*)ourHash
                                 username:(NSString*)username
                              accountName:(NSString*)accountName
                                 protocol:(NSString*)protocol
{
    //changed user fingerprint
}

- (void) otrKit:(OTRKit*)otrKit
 handleSMPEvent:(OTRKitSMPEvent)event
       progress:(double)progress
       question:(NSString*)question
       username:(NSString*)username
    accountName:(NSString*)accountName
       protocol:(NSString*)protocol
{
    
}

- (void) otrKit:(OTRKit *)otrKit handleMessageEvent:(OTRKitMessageEvent)event message:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag error:(NSError *)error {
    //incoming and outgoing errors and other events
    DDLogWarn(@"Message Event: %d Error:%@",(int)event,[OTREncryptionManager errorForMessageEvent:event string:nil].localizedDescription);
    
    if ([tag isKindOfClass:[OTRBaseMessage class]]) {
        __block NSError *error = nil;
        
        // These are the errors caught and 
        switch (event) {
            case OTRKitMessageEventEncryptionError:
            case OTRKitMessageEventReceivedMessageNotInPrivate:
            case OTRKitMessageEventReceivedMessageUnreadable:
            case OTRKitMessageEventReceivedMessageMalformed:
            case OTRKitMessageEventReceivedMessageGeneralError:
            case OTRKitMessageEventReceivedMessageUnrecognized:
                error = [OTREncryptionManager errorForMessageEvent:event string:message];
                break;
            default:
                break;
        }
        if (error != nil) {
            if ([tag isKindOfClass:[OTRBaseMessage class]]) {
                [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    OTRBaseMessage *dbMessage = [[OTRBaseMessage fetchObjectWithUniqueID:((OTRBaseMessage *)tag).uniqueId transaction:transaction] copy];
                    dbMessage.error = error;
                    dbMessage.text = [OTREncryptionManager errorForMessageEvent:event string:nil].localizedDescription;
                    [dbMessage saveWithTransaction:transaction];
                    //Remove the action if there is an error on the parent message.
                    NSString * actionKey = [OTRYapMessageSendAction actionKeyForMessageKey:dbMessage.uniqueId messageCollection:[OTRBaseMessage collection]];
                    [transaction removeObjectForKey:actionKey inCollection:[OTRYapMessageSendAction collection]];
                }];
            }
            
            // Inject message to recipient indicating error
            NSString *errorString = [NSString stringWithFormat:@"OTR Error: %@", [OTREncryptionManager errorForMessageEvent:event string:nil].localizedDescription];
            [self otrKit:self.otrKit injectMessage:errorString username:username accountName:accountName protocol:protocol fingerprint:nil tag:tag];
            // automatically renegotiate a new session when there's an error
            [self.otrKit initiateEncryptionWithUsername:username accountName:accountName protocol:protocol];
        }
    }
}

- (void)        otrKit:(OTRKit*)otrKit
  receivedSymmetricKey:(NSData*)symmetricKey
                forUse:(NSUInteger)use
               useData:(NSData*)useData
              username:(NSString*)username
           accountName:(NSString*)accountName
              protocol:(NSString*)protocol
{
    //DDLogVerbose(@"Received Symetric Key");
}

 ////// Optional //////

- (void)otrKit:(OTRKit *)otrKit willStartGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol
{
    __block OTRAccount *account = nil;
    [self.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        account = [[OTRAccount allAccountsWithUsername:accountName transaction:transaction] firstObject];
    } completionBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OTRWillStartGeneratingPrivateKeyNotification object:account];
    }];
    
    
}

- (void)otrKit:(OTRKit *)otrKit didFinishGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol error:(NSError *)error
{
    __block OTRAccount *account = nil;
    [self.readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [[OTRAccount allAccountsWithUsername:accountName transaction:transaction] firstObject];;
    } completionBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OTRDidFinishGeneratingPrivateKeyNotification object:account];
    }];
}

#pragma - mark Class Methods

+ (NSError *)errorForMessageEvent:(OTRKitMessageEvent)event string:(NSString*)string
{
    
    NSString *eventString = [OTREncryptionManager stringForEvent:event];
    
    NSInteger code = 200 + event;
    NSMutableString *description = [NSMutableString stringWithString:ENCRYPTION_ERROR_STRING()];
    if (string.length) {
        [description appendFormat:@"\n\n%@: %@", string, eventString];
    }
    NSMutableDictionary *userInfo = [@{NSLocalizedDescriptionKey:description} mutableCopy];
    if ([eventString length]) {
        [userInfo setObject:eventString forKey:NSLocalizedFailureReasonErrorKey];
    }
    NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:code userInfo:userInfo];
    
    
    return error;
}

+ (NSString *)stringForEvent:(OTRKitMessageEvent)event
{
    NSString *string = nil;
    switch (event) {
        case OTRKitMessageEventEncryptionRequired:
            string = OTRL_MSGEVENT_ENCRYPTION_REQUIRED_STRING();
            break;
        case OTRKitMessageEventEncryptionError:
            string = OTRL_MSGEVENT_ENCRYPTION_ERROR_STRING();
            break;
        case OTRKitMessageEventConnectionEnded:
            string = OTRL_MSGEVENT_CONNECTION_ENDED_STRING();
            break;
        case OTRKitMessageEventSetupError:
            string = OTRL_MSGEVENT_SETUP_ERROR_STRING();
            break;
        case OTRKitMessageEventMessageReflected:
            string = OTRL_MSGEVENT_MSG_REFLECTED_STRING();
            break;
        case OTRKitMessageEventMessageResent:
            string = OTRL_MSGEVENT_MSG_RESENT_STRING();
            break;
        case OTRKitMessageEventReceivedMessageNotInPrivate:
            string = OTRL_MSGEVENT_RCVDMSG_NOT_IN_PRIVATE_STRING();
            break;
        case OTRKitMessageEventReceivedMessageUnreadable:
            string = OTRL_MSGEVENT_RCVDMSG_UNREADABLE_STRING();
            break;
        case OTRKitMessageEventReceivedMessageMalformed:
            string = OTRL_MSGEVENT_RCVDMSG_MALFORMED_STRING();
            break;
        case OTRKitMessageEventLogHeartbeatReceived:
            string = OTRL_MSGEVENT_LOG_HEARTBEAT_RCVD_STRING();
            break;
        case OTRKitMessageEventLogHeartbeatSent:
            string = OTRL_MSGEVENT_LOG_HEARTBEAT_SENT_STRING();
            break;
        case OTRKitMessageEventReceivedMessageGeneralError:
            string = OTRL_MSGEVENT_RCVDMSG_GENERAL_ERR_STRING();
            break;
        case OTRKitMessageEventReceivedMessageUnencrypted:
            string = OTRL_MSGEVENT_RCVDMSG_UNENCRYPTED_STRING();
            break;
        case OTRKitMessageEventReceivedMessageUnrecognized:
            string = OTRL_MSGEVENT_RCVDMSG_UNRECOGNIZED_STRING();
            break;
        case OTRKitMessageEventReceivedMessageForOtherInstance:
            string = OTRL_MSGEVENT_RCVDMSG_FOR_OTHER_INSTANCE_STRING();
            break;
        default:
            break;
    }
    return string;
}

+ (OTREncryptionMessageState)convertEncryptionState:(NSUInteger)messageState
{
    switch (messageState) {
        case OTRKitMessageStateEncrypted:
            return OTREncryptionMessageStateEncrypted;
        case OTRKitMessageStatePlaintext:
            return OTREncryptionMessageStatePlaintext;
        case OTRKitMessageStateFinished:
            return OTREncryptionMessageStateFinished;
    }
    return OTREncryptionMessageStateError;
}

+ (BOOL) setFileProtection:(NSString*)fileProtection path:(NSString*)path {
    NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:fileProtection forKey:NSFileProtectionKey];
    NSError * error = nil;
    BOOL success = [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:path error:&error];
    if (!success)
    {
        DDLogError(@"error encrypting store: %@", error.userInfo);
    }
    return success;
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        DDLogError(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

#pragma mark OTRDataHandlerDelegate methods

- (void)dataHandler:(OTRDataHandler *)dataHandler transfer:(OTRDataTransfer *)transfer fingerprint:(OTRFingerprint *)fingerprint error:(NSError *)error
{
    DDLogError(@"error with file transfer: %@ %@", transfer, error);
}

- (void)dataHandler:(OTRDataHandler *)dataHandler offeredTransfer:(OTRDataIncomingTransfer *)transfer fingerprint:(OTRFingerprint *)fingerprint
{
    DDLogInfo(@"offered file transfer: %@", transfer);
    
    // for now, just accept all incoming files
    [dataHandler startIncomingTransfer:transfer];
    //Create placeholder for updating progress
    
    OTRIncomingMessage *newMessage = [((OTRIncomingMessage *)transfer.tag) copy];
    newMessage.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithOTRFingerprint:fingerprint.fingerprint];
    newMessage.text = nil;
    
    OTRMediaItem *mediaItem = [OTRMediaItem incomingItemWithFilename:transfer.fileName mimeType:transfer.mimeType];
    
    newMessage.mediaItemUniqueId = mediaItem.uniqueId;
    
    
    //Todo This needs to be moved
//    if ([[OTRAppDelegate appDelegate].messagesViewController otr_isVisible] && [[OTRAppDelegate appDelegate].messagesViewController.buddy.uniqueId isEqualToString:newMessage.buddyUniqueId])
//    {
//        newMessage.read = YES;
//    }
    
    [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:newMessage.buddyUniqueId transaction:transaction];
        buddy.lastMessageId = newMessage.uniqueId;
        [newMessage saveWithTransaction:transaction];
        [buddy saveWithTransaction:transaction];
        [mediaItem saveWithTransaction:transaction];
    }];
    
    
}

- (void)dataHandler:(OTRDataHandler *)dataHandler transfer:(OTRDataTransfer *)transfer progress:(float)progress fingerprint:(OTRFingerprint *)fingerprint
{
    DDLogInfo(@"[OTRDATA]file transfer %@ progress: %f", transfer.transferId, progress);
    
    [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRBaseMessage *tagMessage = transfer.tag;
        OTRBaseMessage *databaseMessage = [OTRBaseMessage fetchObjectWithUniqueID:tagMessage.uniqueId transaction:transaction];
        OTRMediaItem *mediaItem = [OTRMediaItem fetchObjectWithUniqueID:databaseMessage.mediaItemUniqueId transaction:transaction];
        mediaItem.transferProgress = progress;
        [mediaItem saveWithTransaction:transaction];
        [mediaItem touchParentMessageWithTransaction:transaction];
    }];
    
}

- (void)dataHandler:(OTRDataHandler *)dataHandler transferComplete:(OTRDataTransfer *)transfer fingerprint:(OTRFingerprint *)fingerprint
{
    DDLogInfo(@"transfer complete: %@", transfer);
    if ([transfer isKindOfClass:[OTRDataOutgoingTransfer class]]) {
        [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            OTROutgoingMessage *tagMessage = transfer.tag;
            OTROutgoingMessage *message = [OTROutgoingMessage fetchObjectWithUniqueID:tagMessage.uniqueId transaction:transaction];
            message.delivered = YES;
            if (message.dateSent == nil) {
                message.dateSent = [NSDate date];
            }
            message.dateDelivered = [NSDate date];
            
            OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:message.uniqueId transaction:transaction];
            buddy.lastMessageId = message.uniqueId;
            [message saveWithTransaction:transaction];
            [buddy saveWithTransaction:transaction];
        }];
    }
    else if ([transfer isKindOfClass:[OTRDataIncomingTransfer class]]) {
        
        __block OTRIncomingMessage *tagMessage = transfer.tag;
        
        __block OTRIncomingMessage *message = nil;
        __block OTRMediaItem *mediaItem = nil;
        __block OTRBuddy *buddy = nil;
        
        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            message = [OTRIncomingMessage fetchObjectWithUniqueID:tagMessage.uniqueId transaction:transaction];
            mediaItem = [OTRMediaItem fetchObjectWithUniqueID:message.mediaItemUniqueId transaction:transaction];
            buddy = [OTRBuddy fetchObjectWithUniqueID:message.uniqueId transaction:transaction];
        }];
        
        mediaItem.transferProgress = 1;
        
        if ([mediaItem isKindOfClass:[OTRAudioItem class]]) {
            OTRAudioItem *audioItem = (OTRAudioItem *)mediaItem;
            
            [[OTRMediaFileManager sharedInstance] setData:transfer.fileData forItem:audioItem buddyUniqueId:message.buddyUniqueId completion:^(NSInteger bytesWritten, NSError *error) {
                
                NSURL *url = [[OTRMediaServer sharedInstance] urlForMediaItem:audioItem buddyUniqueId:message.buddyUniqueId];
                [audioItem populateFromDataAtUrl:url];
                
                [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [audioItem saveWithTransaction:transaction];
                    [message saveWithTransaction:transaction];
                    buddy.lastMessageId = message.uniqueId;
                    [buddy saveWithTransaction:transaction];
                }];
                
                
            } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
            
        } else if ([mediaItem isKindOfClass:[OTRImageItem class]]) {
            OTRImageItem *imageItem = (OTRImageItem *)mediaItem;
            
            UIImage *tempImage = [UIImage imageWithData:transfer.fileData];
            imageItem.size = tempImage.size;
            
            [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [message saveWithTransaction:transaction];
                [imageItem saveWithTransaction:transaction];
                buddy.lastMessageId = message.uniqueId;
                [buddy saveWithTransaction:transaction];
            } completionBlock:^{
                [[OTRMediaFileManager sharedInstance] setData:transfer.fileData forItem:imageItem buddyUniqueId:message.buddyUniqueId completion:^(NSInteger bytesWritten, NSError *error) {
                    [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                        [imageItem touchParentMessageWithTransaction:transaction];
                    }];
                } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
            }];
             
            
        } else if ([mediaItem isKindOfClass:[OTRVideoItem class]]) {
            OTRVideoItem *videoItem = (OTRVideoItem *)mediaItem;
            
            [[OTRMediaFileManager sharedInstance] setData:transfer.fileData forItem:videoItem buddyUniqueId:message.buddyUniqueId completion:^(NSInteger bytesWritten, NSError *error) {
                
                
                [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [videoItem saveWithTransaction:transaction];
                    [message saveWithTransaction:transaction];
                    buddy.lastMessageId = message.uniqueId;
                    [buddy saveWithTransaction:transaction];
                }];
                
            } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        }
    }
}


@end
