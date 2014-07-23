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
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "YapDatabaseFullTextSearch.h"

#import "OTRYapPushAccount.h"
#import "OTRYapPushDevice.h"
#import "OTRYapPushToken.h"

NSString *OTRConversationGroup = @"Conversation";
NSString *OTRConversationDatabaseViewExtensionName = @"OTRConversationDatabaseViewExtensionName";
NSString *OTRChatDatabaseViewExtensionName = @"OTRChatDatabaseViewExtensionName";
NSString *OTRBuddyDatabaseViewExtensionName = @"OTRBuddyDatabaseViewExtensionName";
NSString *OTRBuddyNameSearchDatabaseViewExtensionName = @"OTRBuddyBuddyNameSearchDatabaseViewExtensionName";
NSString *OTRAllBuddiesDatabaseViewExtensionName = @"OTRAllBuddiesDatabaseViewExtensionName";
NSString *OTRAllSubscriptionRequestsViewExtensionName = @"AllSubscriptionRequestsViewExtensionName";
NSString *OTRAllPushAccountInfoViewExtensionName = @"OTRAllPushAccountInfoViewExtensionName";

NSString *OTRAllAccountGroup = @"All Accounts";
NSString *OTRAllAccountDatabaseViewExtensionName = @"OTRAllAccountDatabaseViewExtensionName";
NSString *OTRChatMessageGroup = @"Messages";
NSString *OTRBuddyGroup = @"Buddy";
NSString *OTRAllPresenceSubscriptionRequestGroup = @"OTRAllPresenceSubscriptionRequestGroup";

NSString *OTRPushTokenGroup = @"Tokens";
NSString *OTRPushDeviceGroup = @"Devices";
NSString *OTRPushAccountGroup = @"Account";

@implementation OTRDatabaseView



+ (BOOL)registerConversationDatabaseView
{
    YapDatabaseView *conversationView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRConversationDatabaseViewExtensionName];
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
            [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
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
                
                [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                    lastMessage1 = [buddy1 lastMessageWithTransaction:transaction];
                }];
                
                [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                    lastMessage2 = [buddy2 lastMessageWithTransaction:transaction];
                }];
                
                return [lastMessage2.date compare:lastMessage1.date];
            }
        }
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [NSSet setWithObject:[OTRBuddy collection]];
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@""
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRConversationDatabaseViewExtensionName];
}




+ (BOOL)registerAllAccountsDatabaseView
{
    YapDatabaseView *accountView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllAccountDatabaseViewExtensionName];
    if (accountView) {
        return YES;
    }
    
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithKeyBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithKey;
    groupingBlock = ^NSString *(NSString *collection, NSString *key){
        
        if ([collection isEqualToString:[OTRAccount collection]])
        {
            return OTRAllAccountGroup;
        }
        
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
        if ([group isEqualToString:OTRAllAccountGroup]) {
            if ([obj1 isKindOfClass:[OTRAccount class]] && [obj1 isKindOfClass:[OTRAccount class]]) {
                OTRAccount *account1 = (OTRAccount *)obj1;
                OTRAccount *account2 = (OTRAccount *)obj2;
                
                return [account1.displayName compare:account2.displayName options:NSCaseInsensitiveSearch];
            }
        }
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [NSSet setWithObject:[OTRAccount collection]];
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@""
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllAccountDatabaseViewExtensionName];
}

+ (BOOL)registerChatDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRChatDatabaseViewExtensionName]) {
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
            return ((OTRMessage *)object).buddyUniqueId;
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
    options.allowedCollections = [NSSet setWithObject:[OTRMessage collection]];
    
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@""
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRChatDatabaseViewExtensionName];
}

+ (BOOL)registerBuddyDatabaseView
{
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithKeyBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithKeyBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithKey;
    
    groupingBlock = ^NSString *(NSString *collection, NSString *key){
        
        return key;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithKey;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1,
                     NSString *collection2, NSString *key2){
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [NSSet setWithObject:[OTRBuddy collection]];
    
    
    YapDatabaseView *view = [[[OTRDatabaseManager sharedInstance].database registeredExtensions] objectForKey:OTRBuddyDatabaseViewExtensionName];
    int version = 1;
    if (view){
        [[OTRDatabaseManager sharedInstance].database unregisterExtension:OTRBuddyDatabaseViewExtensionName];
        version = [view.versionTag intValue];
        version += 1;
    }
    
    view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:[NSString stringWithFormat:@"%d",version] options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRBuddyDatabaseViewExtensionName];
    
}

+ (BOOL)registerBuddyNameSearchDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRBuddyNameSearchDatabaseViewExtensionName]) {
        return YES;
    }
    
    NSArray *propertiesToIndex = @[OTRBuddyAttributes.username,OTRBuddyAttributes.displayName];
    
    YapDatabaseFullTextSearchBlockType blockType = YapDatabaseFullTextSearchBlockTypeWithObject;
    YapDatabaseFullTextSearchWithObjectBlock block = ^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
        
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            
            if([buddy.username length]) {
                [dict setObject:buddy.username forKey:OTRBuddyAttributes.username];
            }
            
            if ([buddy.displayName length]) {
                [dict setObject:buddy.displayName forKey:OTRBuddyAttributes.displayName];
            }
            
            
        }
    };
    
    YapDatabaseFullTextSearch *fullTextSearch = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:propertiesToIndex
                                                                                      block:block
                                                                                  blockType:blockType];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:fullTextSearch withName:OTRBuddyNameSearchDatabaseViewExtensionName];
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
        
        if ([object isKindOfClass:[OTRBuddy class]]) {
            return OTRBuddyGroup;
        }
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    sortingBlock =  ^(NSString *group, NSString *collection1, NSString *key1, id obj1, NSString *collection2, NSString *key2, id obj2) {
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
        
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [NSSet setWithObject:[OTRBuddy collection]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:@"" options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRAllBuddiesDatabaseViewExtensionName];

}

+ (BOOL)registerAllSubscriptionRequestsView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllSubscriptionRequestsViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithKeyBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithKey;
    groupingBlock = ^NSString *(NSString *collection, NSString *key){
        
        if ([collection isEqualToString:[OTRXMPPPresenceSubscriptionRequest collection]])
        {
            return OTRAllPresenceSubscriptionRequestGroup;
        }
        
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
        OTRXMPPPresenceSubscriptionRequest *request1 = (OTRXMPPPresenceSubscriptionRequest *)obj1;
        OTRXMPPPresenceSubscriptionRequest *request2 = (OTRXMPPPresenceSubscriptionRequest *)obj2;
        
        if (request1 && request2) {
            return [request1.date compare:request2.date];
        }
        
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [NSSet setWithObject:[OTRXMPPPresenceSubscriptionRequest collection]];
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@""
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllSubscriptionRequestsViewExtensionName];
}

+ (BOOL)registerPushView
{
    /*if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllPushAccountInfoViewExtensionName]) {
        return YES;
    }*/
    
    [[OTRDatabaseManager sharedInstance].database unregisterExtension:OTRAllPushAccountInfoViewExtensionName];
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithKeyBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    __block NSString *pushAccountCollection = [OTRYapPushAccount collection];
    __block NSString *pushDeviceCollection  = [OTRYapPushDevice collection];
    __block NSString *pushTokenCollection   = [OTRYapPushToken collection];
    
    groupingBlockType = YapDatabaseViewBlockTypeWithKey;
    groupingBlock = ^NSString *(NSString *collection, NSString *key){
        
        if ([collection isEqualToString:pushAccountCollection])
        {
            return OTRPushAccountGroup;
        }
        else if ([collection isEqualToString:pushDeviceCollection])
        {
            return OTRPushDeviceGroup;
        }
        else if ([collection isEqualToString:pushTokenCollection])
        {
            return OTRPushTokenGroup;
        }
        
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
#warning TODO: Needs sorting method
        
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [NSSet setWithArray:@[pushDeviceCollection,pushAccountCollection,pushTokenCollection]];
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@"1"
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllPushAccountInfoViewExtensionName];
}

@end
