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

NSString *OTRConversationGroup = @"Conversation";
NSString *OTRConversationDatabaseViewExtensionName = @"OTRConversationDatabaseViewExtensionName";
NSString *OTRChatDatabaseViewExtensionName = @"OTRChatDatabaseViewExtensionName";
NSString *OTRBuddyDatabaseViewExtensionName = @"OTRBuddyDatabaseViewExtensionName";

NSString *OTRAllAccountGroup = @"All Accounts";
NSString *OTRAllAccountDatabaseViewExtensionName = @"OTRAllAccountDatabaseViewExtensionName";
NSString *OTRChatMessageGroup = @"Messages";
NSString *OTRBuddyGroup = @"Buddy";

@implementation OTRDatabaseView



+ (BOOL)registerConversationDatabaseView
{
    YapDatabaseView *conversationView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRConversationDatabaseViewExtensionName];
    if (conversationView) {
        return;
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
                
                return [buddy1.lastMessageDate compare:buddy2.lastMessageDate];
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
        return;
    }
    
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[OTRAccount class]])
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
    
    
    YapDatabaseView *view = [[[OTRDatabaseManager sharedInstance].database registeredExtensions] objectForKey:OTRChatDatabaseViewExtensionName];
    int version = 1;
    if (view) {
        [[OTRDatabaseManager sharedInstance].database unregisterExtension:OTRChatDatabaseViewExtensionName];
        version = [view.versionTag intValue];
        version += 1;
    }
    
    
    
    view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:[NSString stringWithFormat:@"%d",version]
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

@end
