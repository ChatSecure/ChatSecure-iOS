//
//  OTRDatabaseView.m
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseView.h"
@import YapDatabase.YapDatabaseView;
@import YapDatabase.YapDatabaseFullTextSearch;
@import YapDatabase.YapDatabaseFilteredView;
#import "OTRDatabaseManager.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRXMPPPresenceSubscriptionRequest.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

NSString *OTRConversationGroup = @"Conversation";
NSString *OTRConversationDatabaseViewExtensionName = @"OTRConversationDatabaseViewExtensionName";
NSString *OTRChatDatabaseViewExtensionName = @"OTRChatDatabaseViewExtensionName";
NSString *OTRBuddyNameSearchDatabaseViewExtensionName = @"OTRBuddyBuddyNameSearchDatabaseViewExtensionName";
NSString *OTRAllBuddiesDatabaseViewExtensionName = @"OTRAllBuddiesDatabaseViewExtensionName";
NSString *OTRAllSubscriptionRequestsViewExtensionName = @"AllSubscriptionRequestsViewExtensionName";
NSString *OTRAllPushAccountInfoViewExtensionName = @"OTRAllPushAccountInfoViewExtensionName";
NSString *OTRUnreadMessagesViewExtensionName = @"OTRUnreadMessagesViewExtensionName";

NSString *OTRAllAccountGroup = @"All Accounts";
NSString *OTRAllAccountDatabaseViewExtensionName = @"OTRAllAccountDatabaseViewExtensionName";
NSString *OTRChatMessageGroup = @"Messages";
NSString *OTRBuddyGroup = @"Buddy";
NSString *OTRAllPresenceSubscriptionRequestGroup = @"OTRAllPresenceSubscriptionRequestGroup";
NSString *OTRUnreadMessageGroup = @"Unread Messages";

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
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key, id object) {
        if ([object conformsToProtocol:@protocol(OTRThreadOwner)]) {
            if ([object isKindOfClass:[OTRBuddy class]])
            {
                OTRBuddy *buddy = (OTRBuddy *)object;
                if (buddy.lastMessageDate) {
                    return OTRConversationGroup;
                }
            } else {
                return OTRConversationGroup;
            }
        }
        return nil; // exclude from view
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:OTRConversationGroup]) {
            if ([object1 conformsToProtocol:@protocol(OTRThreadOwner)] && [object2 conformsToProtocol:@protocol(OTRThreadOwner)]) {
                id <OTRThreadOwner> thread1 = object1;
                id <OTRThreadOwner> thread2 = object2;
                
                return [[thread2 lastMessageDate] compare:[thread1 lastMessageDate]];
            }
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    NSSet *whiteListSet = [NSSet setWithObjects:[OTRBuddy collection],[OTRXMPPRoom collection], nil];
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:whiteListSet];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"2"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRConversationDatabaseViewExtensionName];
}




+ (BOOL)registerAllAccountsDatabaseView
{
    YapDatabaseView *accountView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllAccountDatabaseViewExtensionName];
    if (accountView) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key) {
        if ([collection isEqualToString:[OTRAccount collection]])
        {
            return OTRAllAccountGroup;
        }
        
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
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

+ (BOOL)registerChatDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRChatDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key, id object) {
        if ([object conformsToProtocol:@protocol(OTRMesssageProtocol)])
        {
            return [((id <OTRMesssageProtocol>)object) threadId];
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([object1 conformsToProtocol:@protocol(OTRMesssageProtocol)] && [object2 conformsToProtocol:@protocol(OTRMesssageProtocol)]) {
            id <OTRMesssageProtocol> message1 = (id <OTRMesssageProtocol>)object1;
            id <OTRMesssageProtocol> message2 = (id <OTRMesssageProtocol>)object2;
            
            return [[message1 date] compare:[message2 date]];
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    NSSet *whitelist = [NSSet setWithObjects:[OTRMessage collection],[OTRXMPPRoomMessage collection], nil];
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:whitelist];
    
    
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"1"
                                                              options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRChatDatabaseViewExtensionName];
}

+ (BOOL)registerBuddyNameSearchDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRBuddyNameSearchDatabaseViewExtensionName]) {
        return YES;
    }
    
    NSArray *propertiesToIndex = @[OTRBuddyAttributes.username,OTRBuddyAttributes.displayName];
    
    YapDatabaseFullTextSearchHandler *searchHandler = [YapDatabaseFullTextSearchHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
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
    }];
    
    YapDatabaseFullTextSearch *fullTextSearch = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:propertiesToIndex handler:searchHandler];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:fullTextSearch withName:OTRBuddyNameSearchDatabaseViewExtensionName];
}

+ (BOOL)registerAllBuddiesDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllBuddiesDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRBuddy class]]) {
            
            //Checking to see if the buddy username is equal to the account username in order to remove 'self' buddy
            OTRBuddy *buddy = (OTRBuddy *)object;
            OTRAccount *account = [buddy accountWithTransaction:transaction];
            if (![account.username isEqualToString:buddy.username]) {
                return OTRBuddyGroup;
            }
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        
        OTRBuddy *buddy1 = (OTRBuddy *)object1;
        OTRBuddy *buddy2 = (OTRBuddy *)object2;
        
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
    }];
    
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"2"
                                                              options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRAllBuddiesDatabaseViewExtensionName];

}

+ (BOOL)registerAllSubscriptionRequestsView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllSubscriptionRequestsViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key) {
        if ([collection isEqualToString:[OTRXMPPPresenceSubscriptionRequest collection]])
        {
            return OTRAllPresenceSubscriptionRequestGroup;
        }
        
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        
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
    
    YapDatabaseViewFiltering *viewFiltering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection, NSString *key, id object) {
        
        if ([object isKindOfClass:[OTRMessage class]]) {
            return !((OTRMessage *)object).isRead;
        }
        return NO;
    }];
    
    YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:OTRChatDatabaseViewExtensionName
                                                                                          filtering:viewFiltering];
    
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:filteredView withName:OTRUnreadMessagesViewExtensionName];
}

@end
