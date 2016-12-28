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
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRXMPPAccount.h"
#import "OTROMEMODevice.h"
@import OTRAssets;

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
                buddy.avatarData = UIImagePNGRepresentation([UIImage imageNamed:imageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil]);
                buddy.displayName = name;
                buddy.username = name;
                buddy.accountUniqueId  = account.uniqueId;
                buddy.status = OTRThreadStatusAvailable;
                buddy.preferredSecurity = OTRSessionSecurityOMEMO;
                OTROMEMODevice *device = [[OTROMEMODevice alloc] initWithDeviceId:@(1) trustLevel:OMEMOTrustLevelTrustedTofu parentKey:buddy.uniqueId parentCollection:[buddy.class collection] publicIdentityKeyData:[NSData data] lastSeenDate:[NSDate date]];
                [device saveWithTransaction:transaction];
            }
            
            buddy.status = (NSInteger)OTRThreadStatusAvailable+idx;
            
            NSArray *textArray = [self shuffleHelloArray:helloArray];
            
            [buddy saveWithTransaction:transaction];
            
            [textArray enumerateObjectsUsingBlock:^(NSString *text, NSUInteger index, BOOL *stop) {
                OTRBaseMessage *message = nil;
                
                if (index % 2) {
                    message = [[OTRIncomingMessage alloc] init];
                    ((OTRIncomingMessage *)message).read = YES;
                }
                else {
                    OTROutgoingMessage *outgoingMessage = [[OTROutgoingMessage alloc] init];
                    outgoingMessage.delivered = YES;
                    outgoingMessage.dateSent = [NSDate date];
                    message = outgoingMessage;
                }
                
                message.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithOMEMODevice:@"" collection:@""];
                
                message.text = text;
                message.buddyUniqueId = buddy.uniqueId;
                NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                [dateComponents setHour:(-1*index)];
                message.date = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
                
                buddy.lastMessageId = message.uniqueId;
                
                [message saveWithTransaction:transaction];
            }];
            
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
