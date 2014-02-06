//
//  OTRRosterStorage.m
//  Off the Record
//
//  Created by David on 10/18/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRRosterStorage.h"

#import "OTRManagedBuddy.h"
#import "OTRManagedAccount.h"

#import "OTRAccountsManager.h"
#import "OTRManagedGroup.h"

#import "OTRConstants.h"

#import "Strings.h"

#import "OTRLog.h"

@implementation OTRRosterStorage

-(id)init {
    if (self = [super init]) {
        isPopulatingRoster  = NO;
    }
    return self;
}

- (BOOL)configureWithParent:(XMPPRoster *)aParent queue:(dispatch_queue_t)queue
{
    return YES;
}

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream
{
    DDLogInfo(@"Begin Roster Population: %@",stream);
    isPopulatingRoster = YES;
}

- (void)endRosterPopulationForXMPPStream:(XMPPStream *)stream
{
    DDLogInfo(@"End Roster Population: %@",stream);
    isPopulatingRoster = NO;
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
}

- (void)handleRosterItem:(NSXMLElement *)item xmppStream:(XMPPStream *)stream
{
    DDLogInfo(@"Item: %@",item);
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSString *jidStr = [item attributeStringValueForName:@"jid"];
    XMPPJID *jid = [[XMPPJID jidWithString:jidStr] bareJID];
    
    OTRManagedBuddy * user = [self buddyWithJID:jid xmppStream:stream inContext:localContext];
    
    NSString *subscription = [item attributeStringValueForName:@"subscription"];
    if ([subscription isEqualToString:@"remove"])
    {
        if (user)
        {
            [user MR_deleteInContext:localContext];
        }
    }
    else if(user)
    {
        [self updateUser:user updateWithItem:item];
    }
    
    if (!isPopulatingRoster) {
        [localContext MR_saveToPersistentStoreAndWait];
    }
}

- (void)handlePresence:(XMPPPresence *)presence xmppStream:(XMPPStream *)stream
{
    DDLogInfo(@"Handle Presence: %@",presence);
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];

    OTRManagedBuddy * user = [self buddyWithJID:[presence from] xmppStream:stream inContext:context];
    
    if ([[presence type] isEqualToString:@"unavailable"] || [presence isErrorPresence]) {
        [user newStatusMessage:OFFLINE_STRING status:OTRBuddyStatusOffline incoming:YES inContext:context];
    }
    else if (user) {
        OTRBuddyStatus buddyStatus;
        switch (presence.intShow)
        {
            case 0  :
                buddyStatus = OTRBuddyStatusDnd;
                break;
            case 1  :
                buddyStatus = OTRBuddyStatusXa;
                break;
            case 2  :
                buddyStatus = OTRBuddyStatusAway;
                break;
            case 3  :
                buddyStatus = OTRBuddyStatusAvailable;
                break;
            case 4  :
                buddyStatus = OTRBuddyStatusAvailable;
                break;
            default :
                buddyStatus = OTRBuddyStatusOffline;
                break;
        }
        [user newStatusMessage:[presence status] status:buddyStatus incoming:YES inContext:context];
    }
    [context MR_saveToPersistentStoreAndWait];
}

- (BOOL)userExistsWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedBuddy * user = [OTRManagedBuddy fetchWithName:[jid bare] account:[self accountForStream:stream inContext:context] inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
    if (user) {
        return YES;
    }
    return NO;
}

- (void)clearAllResourcesForXMPPStream:(XMPPStream *)stream
{
    
}

- (void)clearAllUsersAndResourcesForXMPPStream:(XMPPStream *)stream
{
    /*
     I don't think we want to delete buddies because this would also delete any conversations
     
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedAccount * account = [self accountForStream:stream inContext:localContext];
    [account.buddies enumerateObjectsUsingBlock:^(OTRManagedBuddy * buddy, BOOL *stop) {
        [buddy MR_deleteInContext:localContext];
    }];
    [localContext MR_saveToPersistentStoreAndWait];
    */
}

- (NSArray *)jidsForXMPPStream:(XMPPStream *)stream
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSMutableArray * jidArray = [NSMutableArray array];
    OTRManagedAccount * account = [self accountForStream:stream inContext:localContext];
    [account.buddies enumerateObjectsUsingBlock:^(OTRManagedBuddy * buddy, BOOL *stop) {
        [jidArray addObject:[XMPPJID jidWithString:buddy.accountName]];
    }];
    return jidArray;
}

- (void)setPhoto:(UIImage *)image forUserWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedBuddy * user = [self buddyWithJID:jid xmppStream:stream inContext:localContext];
    user.photo = image;
    [localContext MR_saveToPersistentStoreAndWait];
}

-(void)updateUser:(OTRManagedBuddy *)user updateWithItem: (NSXMLElement *)item
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    user.displayName = [item attributeStringValueForName:@"name"];
    
    NSArray *groupItems = [item elementsForName:@"group"];
	__block NSString *groupName = nil;
    
    [user removeGroups:user.groups];
    
    if ([groupItems count]) {
        [groupItems enumerateObjectsUsingBlock:^(NSXMLElement *groupElement, NSUInteger idx, BOOL *stop) {
            groupName = [groupElement stringValue];
            [user addToGroup:groupName inContext:context];
        }];
    }
    else{
        [user addToGroup:DEFAULT_BUDDY_GROUP_STRING inContext:context];
    }
    
    if ([self isPendingApprovalElement:item]) {
        [user newStatusMessage:PENDING_APPROVAL_STRING status:OTRBuddyStatusOffline incoming:YES inContext:context];
    }
    
    [context MR_saveToPersistentStoreAndWait];
    
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

-(OTRManagedBuddy *)buddyWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream inContext:(NSManagedObjectContext *)context
{
    return [OTRManagedBuddy fetchOrCreateWithName:[jid bare] account:[self accountForStream:stream inContext:context] inContext:context];
}

-(OTRManagedAccount *)accountForStream:(XMPPStream *)stream inContext:(NSManagedObjectContext *)context
{
    //fixme to new constants of finding account
    return [OTRAccountsManager accountForProtocol:@"xmpp" accountName:[stream.myJID bare] inContext:context];
}

@end
