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
#import "OMEMODevice.h"
#import "OTRBuddyCache.h"
#import "OTRPasswordGenerator.h"
#import "ChatSecureCoreCompat-Swift.h"
@import OTRAssets;

@implementation OTRChatDemo

+ (void)loadDemoChatInDatabase
{
    NSArray *buddyNames = @[@"Martin Hellman",@"Nikita Borisov",@"Whitfield Diffie"];
    NSString *accountName = @"username@example.com";
    NSArray *helloArray = @[@"Hello",
                            @"Bonjour",
                            @"Hallo",
                            @"你好",
                            @"Здравствуйте",
                            @"もしもし",
                            @"Merhaba",@"مرحبا",
                            @"Olá"];
    
    [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        [transaction removeAllObjectsInAllCollections];
        
        OTRXMPPAccount *account = [[OTRXMPPAccount alloc] initWithUsername:accountName accountType:OTRAccountTypeJabber];
        [account saveWithTransaction:transaction];
        
        NSArray *avatarImageNames = @[@"avatar_fox",@"avatar_otter",@"avatar_badger"];
        
        [buddyNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            NSString *firstName = [[name componentsSeparatedByString:@" "].firstObject lowercaseString];
            NSString *jidString = [NSString stringWithFormat:@"%@@example.com", firstName];
            XMPPJID *jid = [XMPPJID jidWithString:jidString];
            OTRXMPPBuddy * buddy = [OTRXMPPBuddy fetchBuddyWithJid:jid accountUniqueId:account.uniqueId transaction:transaction];
            if (!buddy) {
                buddy = [[OTRXMPPBuddy alloc] init];
                NSString *imageName = avatarImageNames[idx];
                buddy.avatarData = UIImagePNGRepresentation([UIImage imageNamed:imageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil]);
                buddy.displayName = name;
                buddy.username = jidString;
                buddy.accountUniqueId  = account.uniqueId;
                [OTRBuddyCache.shared setThreadStatus:OTRThreadStatusAvailable forBuddy:buddy resource:nil];
                buddy.preferredSecurity = OTRSessionSecurityOMEMO;
                NSData *fingerprintData = [OTRPasswordGenerator randomDataWithLength:32];
                OMEMODevice *device = [[OMEMODevice alloc] initWithDeviceId:@(1) trustLevel:OMEMOTrustLevelTrustedUser parentKey:buddy.uniqueId parentCollection:[buddy.class collection] publicIdentityKeyData:fingerprintData lastSeenDate:[NSDate date]];
                [device saveWithTransaction:transaction];
            }
            
            [OTRBuddyCache.shared setThreadStatus:(NSInteger)OTRThreadStatusAvailable+idx forBuddy:buddy resource:nil];
            
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
                [dateComponents setMinute:(-1*index)];
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

+ (void)loadPerformanceTestChatsInDatabase {
    [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        [transaction removeAllObjectsInAllCollections];
        
        NSString *accountName = @"Account #1";
        OTRXMPPAccount *account = [[OTRXMPPAccount alloc] initWithUsername:accountName accountType:OTRAccountTypeJabber];
        [account saveWithTransaction:transaction];
        
        for (int buddyIndex = 0; buddyIndex < 100; buddyIndex++) {
            NSString *name = [NSString stringWithFormat:@"Buddy #%d", buddyIndex + 1];
            NSString *firstName = [NSString stringWithFormat:@"buddy%d", buddyIndex + 1];
            NSString *jidString = [NSString stringWithFormat:@"%@@example.com", firstName];
            XMPPJID *jid = [XMPPJID jidWithString:jidString];
            OTRXMPPBuddy * buddy = [[OTRXMPPBuddy alloc] initWithJID:jid accountId:account.uniqueId];
            buddy.displayName = name;
            buddy.trustLevel = BuddyTrustLevelRoster;
            [OTRBuddyCache.shared setThreadStatus:OTRThreadStatusAvailable forBuddy:buddy resource:nil];
            buddy.preferredSecurity = OTRSessionSecurityOMEMO;
            NSData *fingerprintData = [OTRPasswordGenerator randomDataWithLength:32];
            OMEMODevice *device = [[OMEMODevice alloc] initWithDeviceId:@(1) trustLevel:OMEMOTrustLevelTrustedUser parentKey:buddy.uniqueId parentCollection:[buddy.class collection] publicIdentityKeyData:fingerprintData lastSeenDate:[NSDate date]];
            [device saveWithTransaction:transaction];
            
            [OTRBuddyCache.shared setThreadStatus:(NSInteger)OTRThreadStatusAvailable forBuddy:buddy resource:nil];
            
            [buddy saveWithTransaction:transaction];
            
            for (int text = 0; text < 100; text++) {
                OTRBaseMessage *message = nil;
                
                if (text % 2) {
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
                
                message.text = [NSString stringWithFormat:@"Message #%d", text];
                message.buddyUniqueId = buddy.uniqueId;
                NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                [dateComponents setMinute:(-1*text)];
                message.date = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
                
                buddy.lastMessageId = message.uniqueId;
                
                [message saveWithTransaction:transaction];
            }
            [buddy saveWithTransaction:transaction];
        }
    }];

}

+ (void)addDummyMessagesForExistingAccount:(NSString*)accountJid toFromBuddy:(NSString*)buddyJid count:(int)count {
    [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        OTRXMPPAccount *account = (OTRXMPPAccount *)[[OTRXMPPAccount allAccountsWithUsername:accountJid transaction:transaction] firstObject];
        if (!account) {return;}
        OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchBuddyWithJid:[XMPPJID jidWithString:buddyJid] accountUniqueId:account.uniqueId transaction:transaction];
        if (!buddy) {return;}

        for (int text = 0; text < count; text++) {
            OTRBaseMessage *message = nil;
            
            if (text % 2) {
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
            
            message.text = [NSString stringWithFormat:@"Message #%d", text];
            message.buddyUniqueId = buddy.uniqueId;
            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
            [dateComponents setMinute:(-1*text)];
            message.date = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
            
            buddy.lastMessageId = message.uniqueId;
            
            [message saveWithTransaction:transaction];
        }
        [buddy saveWithTransaction:transaction];
    }];
}


@end
