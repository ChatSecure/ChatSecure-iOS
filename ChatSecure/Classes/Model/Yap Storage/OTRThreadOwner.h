//
//  OTRThreadOwner.h
//  ChatSecure
//
//  Created by David Chiles on 12/2/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessage.h"

typedef NS_ENUM(NSInteger, OTRThreadStatus) {
    OTRThreadStatusAvailable    = 0,
    OTRThreadStatusAway         = 1,
    OTRThreadStatusDoNotDisturb = 2,
    OTRThreadStatusExtendedAway = 3,
    OTRThreadStatusOffline      = 4
};

@protocol OTRThreadOwner <NSObject>
@required
- (nonnull NSString *)threadName;
- (nonnull NSString *)threadIdentifier;
- (nonnull NSString *)threadCollection;
- (nonnull NSString *)threadAccountIdentifier;
- (void)setCurrentMessageText:(nullable NSString*)text;
- (nullable NSString *)currentMessageText;
- (nullable NSDate*)lastMessageDate;
- (nonnull UIImage *)avatarImage;
- (OTRThreadStatus)currentStatus;
- (nullable id <OTRMesssageProtocol>)lastMessageWithTransaction:(nonnull YapDatabaseReadTransaction *)transaction;
- (void)setAllMessagesAsReadInTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction;
- (BOOL)isGroupThread;


@end


