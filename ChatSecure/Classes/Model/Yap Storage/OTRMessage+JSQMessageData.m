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

@implementation OTRMessage (JSQMessageData)

- (NSString *)sender
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

@end
