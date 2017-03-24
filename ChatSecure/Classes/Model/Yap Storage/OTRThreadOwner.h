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


