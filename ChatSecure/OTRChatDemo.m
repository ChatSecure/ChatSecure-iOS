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
    NSArray *buddyNames = @[@"Martin Hellman",@"Nikita Borisov",@"Whitfield Diffie"];
    NSString *accountName = @"username@domain.com";
    NSArray *helloArray = @[@"Hello",
                            @"Bonjour",
                            @"Hallo",
                            @"你好",
                            @"Здравствуйте",
                            @"もしもし",
                            @"Merhaba",@"مرحبا",
                            @"Olá"];
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        [transaction removeAllObjectsInAllCollections];
        
        OTRXMPPAccount *account = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeJabber];
        account.username = accountName;
        [account saveWithTransaction:transaction];
        
        NSArray *avatarImageNames = @[@"avatar_fox",@"avatar_otter",@"avatar_badger"];
        
        [buddyNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            OTRXMPPBuddy * buddy = [OTRXMPPBuddy fetchBuddyForUsername:name accountName:accountName transaction:transaction];
            if (!buddy) {
                buddy = [[OTRXMPPBuddy alloc] init];
                NSString *imageName = avatarImageNames[idx];
                buddy.avatarData = UIImagePNGRepresentation([UIImage imageNamed:imageName]);
                buddy.displayName = name;
                buddy.username = name;
                buddy.accountUniqueId  = account.uniqueId;
                
            }
            
            buddy.status = (NSInteger)OTRBuddyStatusAvailable+idx;
            
            NSArray *textArray = [self shuffleHelloArray:helloArray];
            
            [buddy saveWithTransaction:transaction];
            
            [textArray enumerateObjectsUsingBlock:^(NSString *text, NSUInteger index, BOOL *stop) {
                OTRMessage *message = [[OTRMessage alloc] init];
                message.text = text;
                message.buddyUniqueId = buddy.uniqueId;
                NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                [dateComponents setHour:(-1*index)];
                message.date = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
                
                if (index % 2) {
                   message.incoming = YES;
                }
                else {
                    message.incoming = NO;
                }
                
                message.read = YES;
                message.transportedSecurely = YES;
                buddy.lastMessageDate = message.date;
                
                [message saveWithTransaction:transaction];
            }];
            
            [buddy updateLastMessageDateWithTransaction:transaction];
            [buddy saveWithTransaction:transaction];
        }];
    }];
}

+ (NSArray *)shuffleHelloArray:(NSArray *)array
{
    NSMutableArray *mutableArray = [array mutableCopy];
    NSUInteger count = [mutableArray count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [mutableArray exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    return mutableArray;
}

@end
