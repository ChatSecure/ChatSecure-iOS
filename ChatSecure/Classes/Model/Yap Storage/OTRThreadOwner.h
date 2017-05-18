//
//  OTRThreadOwner.h
//  ChatSecure
//
//  Created by David Chiles on 12/2/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBaseMessage.h"

typedef NS_ENUM(NSInteger, OTRThreadStatus) {
    OTRThreadStatusUnknown      = 0,
    OTRThreadStatusAvailable    = 1,
    OTRThreadStatusAway         = 2,
    OTRThreadStatusDoNotDisturb = 3,
    OTRThreadStatusExtendedAway = 4,
    OTRThreadStatusOffline      = 5
};

@protocol OTRThreadOwner <NSObject>
@required
/** If thread should be hidden from main lists */
@property (nonatomic, readwrite) BOOL isArchived;
/** Whether or not notifications should be hidden. Computed by comparing current time to muteExpiration. */
@property (nonatomic, readonly) BOOL isMuted;
/** How long until the thread is unmuted. If nil, thread will be considered unmuted. */
@property (nonatomic, strong, nullable) NSDate *muteExpiration;

- (nonnull NSString *)threadName;
- (nonnull NSString *)threadIdentifier;
- (nonnull NSString *)threadCollection;
- (nonnull NSString *)threadAccountIdentifier;
- (void)setCurrentMessageText:(nullable NSString*)text;
- (nullable NSString *)currentMessageText;
- (nonnull UIImage *)avatarImage;
- (OTRThreadStatus)currentStatus;
- (nullable id <OTRMessageProtocol>)lastMessageWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (NSUInteger)numberOfUnreadMessagesWithTransaction:(nonnull YapDatabaseReadTransaction*)transaction;
- (BOOL)isGroupThread;

@end


