//
//  OTRMessage+JSQMessageData.m
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessage+JSQMessageData.h"
#import "OTRDatabaseManager.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRMediaItem.h"
@import YapDatabase;

@implementation OTRBaseMessage (JSQMessageData)

- (NSUInteger)messageHash {
    return [self hash];
}

- (BOOL)isMediaMessage
{
    if ([self.mediaItemUniqueId length]) {
        return YES;
    }
    return NO;
}

- (id<JSQMessageMediaData>)media
{
    __block id <JSQMessageMediaData>media = nil;
    [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        media = [OTRMediaItem fetchObjectWithUniqueID:self.mediaItemUniqueId transaction:transaction];
    }];
    return media;
}

- (NSString *)senderId {
    __block NSString *sender = nil;
    if (self.isMessageIncoming) {
        sender = self.buddyUniqueId;
    } else {
        [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            OTRBuddy *buddy = (OTRBuddy *)[self threadOwnerWithTransaction:transaction];
            OTRAccount *account = [buddy accountWithTransaction:transaction];
            sender = account.uniqueId;
        }];
    }
    return sender;
}

- (NSString *)senderDisplayName {
    __block NSString *sender = @"";
    if (self.isMessageIncoming) {
        [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            OTRBuddy *buddy = (OTRBuddy *)[self threadOwnerWithTransaction:transaction];
            if ([buddy.displayName length]) {
                sender = buddy.displayName;
            }
            else {
                sender = buddy.username;
            }
        }];
    } else {
        [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            OTRBuddy *buddy = (OTRBuddy *)[self threadOwnerWithTransaction:transaction];
            OTRAccount *account = [buddy accountWithTransaction:transaction];
            if ([account.displayName length]) {
                sender = account.displayName;
            }
            else {
                sender = account.username;
            }
        }];
    }
    return sender;
}

@end

