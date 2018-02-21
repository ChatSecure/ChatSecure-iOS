//
//  OTRThreadOwner.h
//  ChatSecure
//
//  Created by David Chiles on 12/2/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBaseMessage.h"

@class OTRAccount;

typedef NS_ENUM(NSInteger, OTRThreadStatus) {
    OTRThreadStatusUnknown      = 0,
    OTRThreadStatusAvailable    = 1,
    OTRThreadStatusAway         = 2,
    OTRThreadStatusDoNotDisturb = 3,
    OTRThreadStatusExtendedAway = 4,
    OTRThreadStatusOffline      = 5
};

@class OMEMODevice;

NS_ASSUME_NONNULL_BEGIN
@protocol OTRThreadOwner <OTRYapDatabaseObjectProtocol>
@required
/** If thread should be hidden from main lists */
@property (nonatomic, readwrite) BOOL isArchived;
/** Whether or not notifications should be hidden. Computed by comparing current time to muteExpiration. */
@property (nonatomic, readonly) BOOL isMuted;
/** How long until the thread is unmuted. If nil, thread will be considered unmuted. */
@property (nonatomic, strong, nullable) NSDate *muteExpiration;

@property (nonatomic, readonly) NSString *threadName;
@property (nonatomic, readonly) NSString *threadIdentifier;
@property (nonatomic, readonly) NSString *threadCollection;
@property (nonatomic, readonly) NSString *threadAccountIdentifier;
@property (nonatomic, readwrite, nullable) NSString *currentMessageText;
@property (nonatomic, readonly) UIImage *avatarImage;
@property (nonatomic, readonly) OTRThreadStatus currentStatus;
/** The database identifier for the thread's most recent message. @warn ⚠️ This is no longer used for fetching with lastMessageWithTransaction: and may be invalid, but is being kept around due to a hack to force-show new threads that are empty. */
@property (nonatomic, strong, readwrite, nullable) NSString* lastMessageIdentifier;
- (nullable id <OTRMessageProtocol>)lastMessageWithTransaction:( YapDatabaseReadTransaction *)transaction;
- (NSUInteger)numberOfUnreadMessagesWithTransaction:( YapDatabaseReadTransaction*)transaction;
@property (nonatomic, readonly) BOOL isGroupThread;

- (nullable OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction;

/** New outgoing message. Unsaved! */
- (id<OTRMessageProtocol>)outgoingMessageWithText:(NSString*)text transaction:(YapDatabaseReadTransaction*)transaction;

/** Translates the preferredSecurity value first if set, otherwise bestTransportSecurityWithTransaction: */
- (OTRMessageTransportSecurity)preferredTransportSecurityWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
/** Returns the best OTRMessageTransportSecurity that this buddy is capable */
- (OTRMessageTransportSecurity)bestTransportSecurityWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
/// returns all OMEMO devices associated with recipients in a chat thread
- (NSArray<OMEMODevice*>*)omemoDevicesWithTransaction:(YapDatabaseReadTransaction*)transaction;

@end
NS_ASSUME_NONNULL_END


