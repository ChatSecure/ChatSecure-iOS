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

@implementation OTRMessage (JSQMessageData)

- (NSString *)senderId
{
    __block NSString *sender = @"";
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRBuddy *buddy = [self buddyWithTransaction:transaction];
        if (self.isIncoming) {
            sender = buddy.uniqueId;
        }
        else {
            OTRAccount *account = [buddy accountWithTransaction:transaction];
            sender = account.uniqueId;
        }
    }];
    return sender;
}

- (NSString *)senderDisplayName {
    __block NSString *sender = @"";
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRBuddy *buddy = [self buddyWithTransaction:transaction];
        if (self.isIncoming) {
            if ([buddy.displayName length]) {
                sender = buddy.displayName;
            }
            else {
                sender = buddy.username;
            }
        }
        else {
            OTRAccount *account = [buddy accountWithTransaction:transaction];
            if ([account.displayName length]) {
                sender = account.displayName;
            }
            else {
                sender = account.username;
            }
        }
    }];
    return sender;
}

- (NSUInteger)messageHash
{
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
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        media = [OTRMediaItem fetchObjectWithUniqueID:self.mediaItemUniqueId transaction:transaction];
    }];
    return media;
}


@end
