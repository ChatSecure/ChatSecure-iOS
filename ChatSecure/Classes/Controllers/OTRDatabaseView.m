//
//  OTRDatabaseView.m
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseView.h"
#import "YapDatabaseView.h"
#import "YapDatabase.h"
#import "OTRDatabaseManager.h"
#import "OTRBuddy.h"
#import "OTRGroup.h"
#import "OTRBuddyGroup.h"

#import "OTRXMPPBuddy.h"
#import "OTRAccount.h"
#import "OTRMessage.h"  
#import "OTRBroadcastGroup.h"
#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "YapDatabaseFullTextSearch.h"
#import "YapDatabaseFilteredView.h"

#import "OTRYapPushAccount.h"
#import "OTRYapPushDevice.h"
#import "OTRYapPushToken.h"

NSString *OTRConversationGroup = @"Conversation";
NSString *OTRConversationDatabaseViewExtensionName = @"OTRConversationDatabaseViewExtensionName";
NSString *OTRChatDatabaseViewExtensionName = @"OTRChatDatabaseViewExtensionName";
NSString *OTRBroadcastChatDatabaseViewExtensionName = @"OTRBroadcastChatDatabaseViewExtensionName";
NSString *OTRGroupDatabaseViewExtensionName = @"OTRGroupDatabaseViewExtensionName";
NSString *OTRBuddyDatabaseViewExtensionName = @"OTRBuddyDatabaseViewExtensionName";
NSString *OTRContactByGroupDatabaseViewExtensionName = @"OTRContactByGroupDatabaseViewExtensionName";

NSString *OTRBuddyNameSearchDatabaseViewExtensionName = @"OTRBuddyBuddyNameSearchDatabaseViewExtensionName";
NSString *OTRChatNameSearchDatabaseViewExtensionName = @"OTRChatNameSearchDatabaseViewExtensionName";

NSString *OTRAllBuddiesDatabaseViewExtensionName = @"OTRAllBuddiesDatabaseViewExtensionName";
NSString *OTRContactDatabaseViewExtensionName = @"OTRContactDatabaseViewExtensionName";

NSString *OTRAllSubscriptionRequestsViewExtensionName = @"AllSubscriptionRequestsViewExtensionName";
NSString *OTRAllPushAccountInfoViewExtensionName = @"OTRAllPushAccountInfoViewExtensionName";
NSString *OTRAllBroadcastListDatabaseViewExtensionName = @"OTRAllBroadcastListDatabaseViewExtensionName";
NSString *OTRUnreadMessagesViewExtensionName = @"OTRUnreadMessagesViewExtensionName";

NSString *OTRAllAccountGroup = @"All Accounts";
NSString *OTRAllGroupsGroup = @"All Groups";
NSString *OTRAllAccountDatabaseViewExtensionName = @"OTRAllAccountDatabaseViewExtensionName";
NSString *OTRChatMessageGroup = @"Messages";
NSString *OTRBuddyGroupList = @"All Buddies";
NSString *OTRAllBroadcastGroupList = @"All Broadcast Groups";
NSString *OTRAllBuddiesGroupList = @"All Buddies to Compose";
NSMutableArray *OTRContactByGroupList;

NSString *OTRAllPresenceSubscriptionRequestGroup = @"OTRAllPresenceSubscriptionRequestGroup";
NSString *OTRUnreadMessageGroup = @"Unread Messages";

NSString *OTRPushTokenGroup = @"Tokens";
NSString *OTRPushDeviceGroup = @"Devices";
NSString *OTRPushAccountGroup = @"Account";

@implementation OTRDatabaseView


+(BOOL)registerAllBroadcastListDatabaseView
{
    YapDatabaseView *broadcastListView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllBroadcastListDatabaseViewExtensionName];
    if (broadcastListView) {
        return YES;
    }
    
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithKeyBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithKey;
    groupingBlock = ^NSString *(NSString *collection, NSString *key){
        
        if ([collection isEqualToString:[OTRBroadcastGroup collection]])
        {
            return OTRAllBroadcastGroupList;
        }
        
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
        if ([group isEqualToString:OTRAllBroadcastGroupList]) {
            if ([obj1 isKindOfClass:[OTRBroadcastGroup class]] && [obj1 isKindOfClass:[OTRBroadcastGroup class]]) {
                OTRBroadcastGroup *broadcastGroup1 = (OTRBroadcastGroup *)obj1;
                OTRBroadcastGroup *broadcastGroup2 = (OTRBroadcastGroup *)obj2;
                
                return [broadcastGroup1.displayName compare:broadcastGroup2.displayName options:NSCaseInsensitiveSearch];
            }
        }
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBroadcastGroup collection]]];
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@""
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllBroadcastListDatabaseViewExtensionName];
}



+ (BOOL)registerContactByGroupDatabaseView
{
    
    OTRContactByGroupList = [[NSMutableArray alloc] init];
    
    YapDatabaseView *contactByGroupView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRContactByGroupDatabaseViewExtensionName];
    if (contactByGroupView) {
        return YES;
    }
    
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRBuddyGroup class]])
        {
            OTRBuddyGroup *buddyGroup = (OTRBuddyGroup *)object;
            
            __block OTRGroup *localGroup = nil;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                localGroup = [[OTRGroup fetchObjectWithUniqueID:buddyGroup.groupUniqueId transaction:transaction] copy];
            }];
            
            
            if(![OTRContactByGroupList containsObject:[@"OTR" stringByAppendingString:localGroup.displayName]])
            {
                [OTRContactByGroupList addObject:[@"OTR" stringByAppendingString:localGroup.displayName]];
                return [@"OTR" stringByAppendingString:localGroup.displayName];
            }
            else{
                return [@"OTR" stringByAppendingString:localGroup.displayName];
            }
            
        }
        
        return nil; // exclude from view
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        
            if ([object1 isKindOfClass:[OTRBuddyGroup class]] && [object2 isKindOfClass:[OTRBuddyGroup class]]) {
                
                
                OTRBuddyGroup* buddyGroup1 = (OTRBuddyGroup *)object1;
                OTRBuddyGroup *buddyGroup2 = (OTRBuddyGroup *)object2;

                __block OTRBuddy *buddy1 = nil;
                __block OTRBuddy *buddy2 = nil;

                [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                    buddy1 = [[OTRBuddy fetchObjectWithUniqueID:buddyGroup1.buddyUniqueId transaction:transaction] copy];
                    buddy2 = [[OTRBuddy fetchObjectWithUniqueID:buddyGroup2.buddyUniqueId transaction:transaction] copy];
                }];
                
                return [buddy1.displayName compare:buddy2.displayName options:NSCaseInsensitiveSearch];

            }
        
            return NSOrderedSame;
        }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddyGroup collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRContactByGroupDatabaseViewExtensionName];
}




+ (BOOL)registerAllAccountsDatabaseView
{
    YapDatabaseView *accountView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllAccountDatabaseViewExtensionName];
    if (accountView) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(NSString *collection, NSString *key) {
        if ([collection isEqualToString:[OTRAccount collection]])
        {
            return OTRAllAccountGroup;
        }
        
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:OTRAllAccountGroup]) {
            if ([object1 isKindOfClass:[OTRAccount class]] && [object2 isKindOfClass:[OTRAccount class]]) {
                OTRAccount *account1 = (OTRAccount *)object1;
                OTRAccount *account2 = (OTRAccount *)object2;
                
                return [account1.displayName compare:account2.displayName options:NSCaseInsensitiveSearch];
            }
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRAccount collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllAccountDatabaseViewExtensionName];

}

+ (BOOL)registerConversationDatabaseView
{
    /*YapDatabaseView *conversationView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRConversationDatabaseViewExtensionName];
     if (conversationView) {
     return YES;
     }
     
     
     YapDatabaseViewBlockType groupingBlockType;
     YapDatabaseViewGroupingWithObjectBlock groupingBlock;
     
     YapDatabaseViewBlockType sortingBlockType;
     YapDatabaseViewSortingWithObjectBlock sortingBlock;
     
     groupingBlockType = YapDatabaseViewBlockTypeWithObject;
     groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
     
     if ([object isKindOfClass:[OTRBuddy class]])
     {
     OTRBuddy *buddy = (OTRBuddy *)object;
     __block BOOL hasMessages = NO;
     [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
     hasMessages = [buddy hasMessagesWithTransaction:transaction];
     }];
     if (hasMessages) {
     return OTRConversationGroup;
     }
     
     }
     
     return nil; // exclude from view
     };
     
     sortingBlockType = YapDatabaseViewBlockTypeWithObject;
     sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
     NSString *collection2, NSString *key2, id obj2){
     if ([group isEqualToString:OTRConversationGroup]) {
     if ([obj1 isKindOfClass:[OTRBuddy class]] && [obj1 isKindOfClass:[OTRBuddy class]]) {
     OTRBuddy *buddy1 = (OTRBuddy *)obj1;
     OTRBuddy *buddy2 = (OTRBuddy *)obj2;
     
     __block OTRMessage *lastMessage1 = nil;
     __block OTRMessage *lastMessage2 = nil;
     
     [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
     lastMessage1 = [buddy1 lastMessageWithTransaction:transaction];
     }];
     
     [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
     lastMessage2 = [buddy2 lastMessageWithTransaction:transaction];
     }];
     
     return [lastMessage2.date compare:lastMessage1.date];
     }
     }
     
     return NSOrderedSame;
     };
     
     
     YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
     options.isPersistent = YES;
     options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
     
     YapDatabaseView *databaseView =
     [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
     groupingBlockType:groupingBlockType
     sortingBlock:sortingBlock
     sortingBlockType:sortingBlockType
     versionTag:@""
     options:options];
     return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRConversationDatabaseViewExtensionName];*/
    
    YapDatabaseView *conversationView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRConversationDatabaseViewExtensionName];
    if (conversationView) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            if (buddy.lastMessageDate) {
                return OTRConversationGroup;
            }
        }
        return nil; // exclude from view
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:OTRConversationGroup]) {
            if ([object1 isKindOfClass:[OTRBuddy class]] && [object2 isKindOfClass:[OTRBuddy class]]) {
                OTRBuddy *buddy1 = (OTRBuddy *)object1;
                OTRBuddy *buddy2 = (OTRBuddy *)object2;
                
                return [buddy2.lastMessageDate compare:buddy1.lastMessageDate];
            }
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRConversationDatabaseViewExtensionName];
}



+ (BOOL)registerGroupDatabaseView
{
    YapDatabaseView *groupView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRGroupDatabaseViewExtensionName];
    if (groupView) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(NSString *collection, NSString *key) {
        if ([collection isEqualToString:[OTRGroup collection]])
        {
            return OTRAllGroupsGroup;
        }
        
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:OTRAllAccountGroup]) {
            if ([object1 isKindOfClass:[OTRGroup class]] && [object2 isKindOfClass:[OTRGroup class]]) {
                OTRGroup *group1 = (OTRGroup *)object1;
                OTRGroup *group2 = (OTRGroup *)object2;
                
                return [group1.displayName compare:group2.displayName options:NSCaseInsensitiveSearch];
            }
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRGroup collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRGroupDatabaseViewExtensionName];
    
}



+ (BOOL)registerChatDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRChatDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRMessage class]])
        {
            return ((OTRMessage *)object).buddyUniqueId;
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([object1 isKindOfClass:[OTRMessage class]] && [object2 isKindOfClass:[OTRMessage class]]) {
            OTRMessage *message1 = (OTRMessage *)object1;
            OTRMessage *message2 = (OTRMessage *)object2;
            
            return [message1.date compare:message2.date];
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRMessage collection]]];
    
    
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"1"
                                                              options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRChatDatabaseViewExtensionName];
}


+ (BOOL)registerBroadcastChatDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRBroadcastChatDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[OTRMessage class]])
        {
            if(((OTRMessage *)object).isBroadcastMessage)
            {
                return ((OTRMessage *)object).broadcastGroupUniqueId;
            }
        }
        return nil;
    
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
        if ([group isEqualToString:OTRChatMessageGroup]) {
            if ([obj1 isKindOfClass:[OTRMessage class]] && [obj1 isKindOfClass:[OTRMessage class]]) {
                OTRMessage *message1 = (OTRMessage *)obj1;
                OTRMessage *message2 = (OTRMessage *)obj2;
                
                return [message1.date compare:message2.date];
            }
        }
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRMessage collection]]];
    
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@""
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRBroadcastChatDatabaseViewExtensionName];
}

+ (BOOL)registerBuddyDatabaseView
{
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(NSString *collection, NSString *key) {
        return key;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withKeyBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, NSString *collection2, NSString *key2) {
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    
    YapDatabaseView *view = [[[OTRDatabaseManager sharedInstance].database registeredExtensions] objectForKey:OTRBuddyDatabaseViewExtensionName];
    int version = 1;
    if (view){
        [[OTRDatabaseManager sharedInstance].database unregisterExtensionWithName:OTRBuddyDatabaseViewExtensionName];
        version = [view.versionTag intValue];
        version += 1;
    }
    
    view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                             sorting:viewSorting
                                          versionTag:[NSString stringWithFormat:@"%d",version]
                                             options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRBuddyDatabaseViewExtensionName];
    
    
}

+ (BOOL)registerBuddyNameSearchDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRBuddyNameSearchDatabaseViewExtensionName]) {
        return YES;
    }
    
    NSArray *propertiesToIndex = @[OTRBuddyAttributes.username, OTRBuddyAttributes.displayName, OTRGroupAttributes.displayName];
    
    YapDatabaseFullTextSearchHandler *searchHandler = [YapDatabaseFullTextSearchHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;

            __block BOOL isPendingApproval = NO;
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
                    isPendingApproval = TRUE;
                }else{
                    isPendingApproval = FALSE;
                }
            }
            if (!isPendingApproval) {
                if([buddy.username length]) {
                    [dict setObject:buddy.username forKey:OTRBuddyAttributes.username];
                }
                
                if ([buddy.displayName length]) {
                    [dict setObject:buddy.displayName forKey:OTRBuddyAttributes.displayName];
                }
                
            }
        }
        
        if ([object isKindOfClass:[OTRGroup class]])
        {
            OTRGroup *group = (OTRGroup *)object;
            [dict setObject:group.displayName forKey:OTRGroupAttributes.displayName];
            
        }

    }];
    
    YapDatabaseFullTextSearch *fullTextSearch = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:propertiesToIndex handler:searchHandler];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:fullTextSearch withName:OTRBuddyNameSearchDatabaseViewExtensionName];
}



+ (BOOL)registerChatNameSearchDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRChatNameSearchDatabaseViewExtensionName]) {
        return YES;
    }
    
        
    NSArray *propertiesToIndex = @[OTRBuddyAttributes.username, OTRBuddyAttributes.displayName, OTRMessageAttributes.text];
    
    YapDatabaseFullTextSearchHandler *searchHandler = [YapDatabaseFullTextSearchHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
        
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            
            if (buddy.lastMessageDate) {

                if([buddy.username length]) {
                    [dict setObject:buddy.username forKey:OTRBuddyAttributes.username];
                }
                
                if ([buddy.displayName length]) {
                    [dict setObject:buddy.displayName forKey:OTRBuddyAttributes.displayName];
                }
                
                /*
                
                [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                    if([buddy hasMessagesWithTransaction:transaction]) {
                        [dict setObject:[buddy lastMessageWithTransaction:transaction].text forKey:OTRMessageAttributes.text];
                        [dict setObject:[buddy lastMessageWithTransaction:transaction].date forKey:OTRMessageAttributes.date];
                    }
                }];*/
            }
            
        }
        
        if ([object isKindOfClass:[OTRMessage class]])
        {
            OTRMessage *message = (OTRMessage *)object;
            
            
            __block OTRBuddy *buddy;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                buddy = [message buddyWithTransaction:transaction];
            }];
            
            /*if([buddy.username length]) {
                [dict setObject:buddy.username forKey:OTRBuddyAttributes.username];
            }
            
            if ([buddy.displayName length]) {
                [dict setObject:buddy.displayName forKey:OTRBuddyAttributes.displayName];
            }*/
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"]; //this is the sqlite's format
            NSString *formattedDateStringTime = [formatter stringFromDate:message.date];
            
            [dict setObject:message.text forKey:OTRMessageAttributes.text];
            [dict setObject:formattedDateStringTime forKey:OTRMessageAttributes.date];
            
            
        }
    }];
    
    YapDatabaseFullTextSearch *fullTextSearch = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:propertiesToIndex handler:searchHandler];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:fullTextSearch withName:OTRChatNameSearchDatabaseViewExtensionName];
}

+ (BOOL)registerAllBuddiesDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllBuddiesDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            __block BOOL isPendingApproval = NO;
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
                    isPendingApproval = TRUE;
                }else{
                    isPendingApproval = FALSE;
                }
            }
            if (!isPendingApproval) {
                return OTRAllBuddiesGroupList;
            }
            
        }
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    sortingBlock =  ^(NSString *group, NSString *collection1, NSString *key1, id obj1, NSString *collection2, NSString *key2, id obj2) {
        if ([group isEqualToString:OTRBuddyGroupList]) {
            OTRBuddy *buddy1 = (OTRBuddy *)obj1;
            OTRBuddy *buddy2 = (OTRBuddy *)obj2;
            
            if (buddy1.status == buddy2.status) {
                NSString *buddy1String = buddy1.username;
                NSString *buddy2String = buddy2.username;
                
                if ([buddy1.displayName length]) {
                    buddy1String = buddy1.displayName;
                }
                
                if ([buddy2.displayName length]) {
                    buddy2String = buddy2.displayName;
                }
                
                return [buddy1String compare:buddy2String options:NSCaseInsensitiveSearch];
            }
            else if (buddy1.status < buddy2.status) {
                return NSOrderedAscending;
            }
            else{
                return NSOrderedDescending;
            }
        }
        return NSOrderedSame;
        
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:@"" options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRAllBuddiesDatabaseViewExtensionName];
}

+ (BOOL)registerContactDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRContactDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            __block BOOL isPendingApproval = NO;
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
                    isPendingApproval = TRUE;
                }else{
                    isPendingApproval = FALSE;
                }
            }
            if (!isPendingApproval) {
                if(![buddy.groupUniqueId count] > 0)
                {
                    return OTRBuddyGroupList;
                }
            }
            
        }
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    sortingBlock =  ^(NSString *group, NSString *collection1, NSString *key1, id obj1, NSString *collection2, NSString *key2, id obj2) {
        if ([group isEqualToString:OTRBuddyGroupList]) {
            OTRBuddy *buddy1 = (OTRBuddy *)obj1;
            OTRBuddy *buddy2 = (OTRBuddy *)obj2;
            
            if (buddy1.status == buddy2.status) {
                NSString *buddy1String = buddy1.username;
                NSString *buddy2String = buddy2.username;
                
                if ([buddy1.displayName length]) {
                    buddy1String = buddy1.displayName;
                }
                
                if ([buddy2.displayName length]) {
                    buddy2String = buddy2.displayName;
                }
                
                return [buddy1String compare:buddy2String options:NSCaseInsensitiveSearch];
            }
            else if (buddy1.status < buddy2.status) {
                return NSOrderedAscending;
            }
            else{
                return NSOrderedDescending;
            }
        }
        return NSOrderedSame;
        
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:@"" options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRContactDatabaseViewExtensionName];
    
}




+ (BOOL)registerAllSubscriptionRequestsView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllSubscriptionRequestsViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(NSString *collection, NSString *key) {
        if ([collection isEqualToString:[OTRXMPPPresenceSubscriptionRequest collection]])
        {
            return OTRAllPresenceSubscriptionRequestGroup;
        }
        
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        
        OTRXMPPPresenceSubscriptionRequest *request1 = (OTRXMPPPresenceSubscriptionRequest *)object1;
        OTRXMPPPresenceSubscriptionRequest *request2 = (OTRXMPPPresenceSubscriptionRequest *)object2;
        
        if (request1 && request2) {
            return [request1.date compare:request2.date];
        }
        
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRXMPPPresenceSubscriptionRequest collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllSubscriptionRequestsViewExtensionName];

}


+ (BOOL)registerUnreadMessagesView
{
    
    YapDatabaseViewFiltering *viewFiltering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(NSString *group, NSString *collection, NSString *key, id object) {
        
        if ([object isKindOfClass:[OTRMessage class]]) {
            return !((OTRMessage *)object).isRead;
        }
        return NO;
    }];
    
    YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:OTRChatDatabaseViewExtensionName
                                                                                          filtering:viewFiltering];
    
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:filteredView withName:OTRUnreadMessagesViewExtensionName];
}



+ (BOOL)registerPushView
{
    /*if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllPushAccountInfoViewExtensionName]) {
     return YES;
     }*/
    
    [[OTRDatabaseManager sharedInstance].database unregisterExtensionWithName:OTRAllPushAccountInfoViewExtensionName];
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(NSString *collection, NSString *key) {
        
        if ([collection isEqualToString:[OTRYapPushAccount collection]])
        {
            return OTRPushAccountGroup;
        }
        else if ([collection isEqualToString:[OTRYapPushDevice collection]])
        {
            return OTRPushDeviceGroup;
        }
        else if ([collection isEqualToString:[OTRYapPushToken collection]])
        {
            return OTRPushTokenGroup;
        }
        
        return nil;
        
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withKeyBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, NSString *collection2, NSString *key2) {
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithArray:@[[OTRYapPushAccount collection],[OTRYapPushDevice collection],[OTRYapPushToken collection]]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1" options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllPushAccountInfoViewExtensionName];
}

@end
