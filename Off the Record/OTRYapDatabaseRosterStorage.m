//
//  OTRYapDatabaseRosterStorage.m
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseRosterStorage.h"

#import "YapDatabaseConnection.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseTransaction.h"
#import "OTRLog.h"
#import "OTRXMPPBuddy.h"
#import "OTRAccount.h"
#import "Strings.h"

@interface OTRYapDatabaseRosterStorage ()

@property (nonatomic, strong) YapDatabaseConnection *connection;
@property (nonatomic, strong) NSString *accountUniqueId;

@end

@implementation OTRYapDatabaseRosterStorage

-(id)init
{
    if (self = [super init]) {
        self.connection = [[OTRDatabaseManager sharedInstance] readWriteDatabaseConnection];
    }
    return self;
}

#pragma - mark Helper Methods

- (OTRAccount *)accountForStream:(XMPPStream *)stream
{
    __block OTRAccount *account = nil;
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [OTRAccount fetchAccountWithUsername:[stream.myJID bare] protocolType:OTRProtocolTypeXMPP transaction:transaction];
    }];
    return account;
}

- (OTRXMPPBuddy *)buddyWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    if (![self.accountUniqueId length]) {
        OTRAccount *account = [self accountForStream:stream];
        self.accountUniqueId = account.uniqueId;
    }
    __block OTRXMPPBuddy *buddy = nil;
    
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [OTRXMPPBuddy fetchBuddyWithUsername:[jid bare] withAccountUniqueId:self.accountUniqueId transaction:transaction];
    }];
    
    if (!buddy) {
        buddy = [[OTRXMPPBuddy alloc] init];
        buddy.username = [jid bare];
        buddy.accountUniqueId = self.accountUniqueId;
    }
    
    return buddy;
}

-(BOOL)isPendingApprovalElement:(NSXMLElement *)item
{
    NSString *subscription = [item attributeStringValueForName:@"subscription"];
	NSString *ask = [item attributeStringValueForName:@"ask"];
	
	if ([subscription isEqualToString:@"none"] || [subscription isEqualToString:@"from"])
    {
        if([ask isEqualToString:@"subscribe"])
        {
            return YES;
        }
    }
    return NO;
}

- (void)updateBuddy:(OTRXMPPBuddy *)buddy withItem:(NSXMLElement *)item
{
    buddy.displayName = [item attributeStringValueForName:@"name"];
    
    if ([self isPendingApprovalElement:item]) {
        //FIXME PendingApproval
        buddy.pendingApproval = YES;
    }
    else {
        buddy.pendingApproval = NO;
    }
    
    [self.connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:buddy forKey:buddy.uniqueId inCollection:[OTRXMPPBuddy collection]];
    }];
}

#pragma - mark XMPPRosterStorage Methods

- (BOOL)configureWithParent:(XMPPRoster *)aParent queue:(dispatch_queue_t)queue
{
    return YES;
}

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);
}
- (void)endRosterPopulationForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);
}

- (void)handleRosterItem:(NSXMLElement *)item xmppStream:(XMPPStream *)stream
{
    NSString *jidStr = [item attributeStringValueForName:@"jid"];
    XMPPJID *jid = [[XMPPJID jidWithString:jidStr] bareJID];
    
    OTRXMPPBuddy *buddy = [self buddyWithJID:jid xmppStream:stream];
    
    NSString *subscription = [item attributeStringValueForName:@"subscription"];
    if ([subscription isEqualToString:@"remove"])
    {
        if (buddy)
        {
            [self.connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [transaction setObject:nil forKey:buddy.uniqueId inCollection:[OTRXMPPBuddy collection]];
            }];
        }
    }
    else if(buddy)
    {
        [self updateBuddy:buddy withItem:item];
    }
    
}

- (void)handlePresence:(XMPPPresence *)presence xmppStream:(XMPPStream *)stream
{
    OTRXMPPBuddy *buddy = [self buddyWithJID:[presence from] xmppStream:stream];
    
    if ([[presence type] isEqualToString:@"unavailable"] || [presence isErrorPresence]) {
        buddy.status = OTRBuddyStatusOffline;
        buddy.statusMessage = OFFLINE_STRING;
    }
    else if (buddy) {
        NSString *defaultMessage = OFFLINE_STRING;
        switch (presence.intShow)
        {
            case 0  :
                buddy.status = OTRBuddyStatusDnd;
                defaultMessage = DO_NOT_DISTURB_STRING;
                break;
            case 1  :
                buddy.status = OTRBuddyStatusXa;
                defaultMessage = EXTENDED_AWAY_STRING;
                break;
            case 2  :
                buddy.status = OTRBuddyStatusAway;
                defaultMessage = AWAY_STRING;
                break;
            case 3  :
            case 4  :
                buddy.status = OTRBuddyStatusAvailable;
                defaultMessage = AVAILABLE_STRING;
                break;
            default :
                buddy.status = OTRBuddyStatusOffline;
                break;
        }
        
        if ([[presence status] length]) {
            buddy.statusMessage = [presence status];
        }
        else {
            buddy.statusMessage = defaultMessage;
        }

    }
    
    [self.connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:buddy forKey:buddy.uniqueId inCollection:[OTRBuddy collection]];
    }];
    
}

- (BOOL)userExistsWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    OTRXMPPBuddy *buddy = [self buddyWithJID:jid xmppStream:stream];
    if (buddy) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void)clearAllResourcesForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);

}
- (void)clearAllUsersAndResourcesForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);

}

- (NSArray *)jidsForXMPPStream:(XMPPStream *)stream
{
    __block NSMutableArray *jidArray = [NSMutableArray array];
    [self.connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[OTRXMPPBuddy collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
            if ([object isKindOfClass:[OTRXMPPBuddy class]]) {
                OTRXMPPBuddy *buddy = (OTRXMPPBuddy *)buddy;
                if ([buddy.username length]) {
                    [jidArray addObject:buddy.username];
                }
            }
        }];
    }];
    return jidArray;
}

@end
