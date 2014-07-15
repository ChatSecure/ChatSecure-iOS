//
//  OTRChatDemo.m
//  Off the Record
//
//  Created by David Chiles on 7/8/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRChatDemo.h"
#import "OTRDatabaseManager.h"

#import "OTRXMPPBuddy.h"
#import "OTRMessage.h"
#import "OTRXMPPAccount.h"

@implementation OTRChatDemo

+ (void)loadDemoChatInDatabase
{
    NSArray *buddyNames = @[@"Tom",@"Susan",@"Julie"];
    NSString *accountName = @"username@domain.com";
    NSArray *messages = @[@"Where are you?",@"Hey!",@"Going to the zoo later?"];
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        
        OTRXMPPAccount *account = [OTRXMPPAccount fetchAccountWithUsername:accountName protocolType:OTRProtocolTypeXMPP transaction:transaction];
        if(!account)
        {
            account = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeJabber];
            account.username = accountName;
            [account saveWithTransaction:transaction];
        }
        
        
        
        
        NSArray *avatarImageNames = @[@"avatar_fox",@"avatar_otter",@"avatar_badger"];
        
        [buddyNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyForUsername:name accountName:accountName protocolType:OTRProtocolTypeXMPP transaction:transaction];
            if (!buddy) {
                buddy = [[OTRXMPPBuddy alloc] init];
                NSString *imageName = avatarImageNames[idx];
                buddy.avatarData = UIImagePNGRepresentation([UIImage imageNamed:imageName]);
                buddy.displayName = name;
                buddy.username = name;
                buddy.accountUniqueId  = account.uniqueId;
                
            }
            
            buddy.status = (NSInteger)OTRBuddyStatusAvailable+idx;
            

            
            OTRMessage *message = [[OTRMessage alloc] init];
            message.text = messages[idx];
            message.buddyUniqueId = buddy.uniqueId;
            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
            [dateComponents setHour:(-1*idx)];
            message.date = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
            
            message.incoming = YES;
            buddy.lastMessageDate = message.date;
            
            [buddy saveWithTransaction:transaction];
            [message saveWithTransaction:transaction];
            
            
        }];
    }];
    
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyForUsername:@"Susan" accountName:@"username@domain.com" protocolType:OTRProtocolTypeXMPP transaction:transaction];
        BOOL hasMessage = [buddy hasMessagesWithTransaction:transaction];
    }];
    
    [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyForUsername:@"Susan" accountName:@"username@domain.com" protocolType:OTRProtocolTypeXMPP transaction:transaction];
        BOOL hasMessage = [buddy hasMessagesWithTransaction:transaction];
    }];
    
}

@end
