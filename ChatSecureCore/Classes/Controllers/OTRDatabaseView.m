//
//  OTRDatabaseView.m
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseView.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRIncomingMessage.h"
#import "OTRLog.h"
#import "OTROutgoingMessage.h"
#import "ChatSecureCoreCompat-Swift.h"

NSString *OTRArchiveFilteredConversationsName = @"OTRFilteredConversationsName";
NSString *OTRBuddyFilteredConversationsName = @"OTRBuddyFilteredConversationsName";
NSString *OTRConversationGroup = @"Conversation";
NSString *OTRConversationDatabaseViewExtensionName = @"OTRConversationDatabaseViewExtensionName";
NSString *OTRChatDatabaseViewExtensionName = @"OTRChatDatabaseViewExtensionName";
NSString *OTRFilteredChatDatabaseViewExtensionName = @"OTRFilteredChatDatabaseViewExtensionName";
NSString *OTRAllBuddiesDatabaseViewExtensionName = @"OTRAllBuddiesDatabaseViewExtensionName";
NSString *OTRArchiveFilteredBuddiesName = @"OTRFilteredBuddiesName";
NSString *OTRAllSubscriptionRequestsViewExtensionName = @"AllSubscriptionRequestsViewExtensionName";
NSString *OTRAllPushAccountInfoViewExtensionName = @"OTRAllPushAccountInfoViewExtensionName";

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

+ (BOOL)registerArchiveFilteredConversationsViewWithDatabase:(YapDatabase *)database {
    YapDatabaseFilteredView *filteredView = [database registeredExtension:OTRArchiveFilteredConversationsName];
    if (filteredView) {
        return YES;
    }
    YapDatabaseView *conversationView = [database registeredExtension:OTRConversationDatabaseViewExtensionName];
    if (!conversationView) {
        return NO;
    }
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = NO;
    BOOL showArchived = NO;
    YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
        if ([object conformsToProtocol:@protocol(OTRThreadOwner)]) {
            id<OTRThreadOwner> threadOwner = object;
            BOOL isArchived = threadOwner.isArchived;
            return showArchived == isArchived;
        }
        return YES;
    }];
    filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:OTRConversationDatabaseViewExtensionName filtering:filtering versionTag:[NSUUID UUID].UUIDString options:options];
    return [database registerExtension:filteredView withName:OTRArchiveFilteredConversationsName];
}

+ (BOOL)registerBuddyFilteredConversationsViewWithDatabase:(YapDatabase *)database {
    YapDatabaseFilteredView *filteredView = [database registeredExtension:OTRBuddyFilteredConversationsName];
    if (filteredView) {
        return YES;
    }
    YapDatabaseView *conversationView = [database registeredExtension:OTRConversationDatabaseViewExtensionName];
    if (!conversationView) {
        return NO;
    }
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    NSSet *whiteListSet = [NSSet setWithObjects:[OTRBuddy collection], nil];
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:whiteListSet];
    YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
        id<OTRThreadOwner> thread = (id<OTRThreadOwner>)object;
        if (![thread conformsToProtocol:@protocol(OTRThreadOwner)]) {
            return NO;
        }
        id<OTRMessageProtocol> lastMessage = [thread lastMessageWithTransaction:transaction];
        if (!lastMessage) {
            return NO;
        }
        return YES;
    }];
    filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:OTRConversationDatabaseViewExtensionName filtering:filtering versionTag:@"1" options:options];
    return [database registerExtension:filteredView withName:OTRBuddyFilteredConversationsName];
}
+ (BOOL)registerConversationDatabaseViewWithDatabase:(YapDatabase *)database
{
    YapDatabaseView *conversationView = [database registeredExtension:OTRConversationDatabaseViewExtensionName];
    if (conversationView) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key, id object) {
        if ([object conformsToProtocol:@protocol(OTRThreadOwner)]) {
            if ([object isKindOfClass:[OTRXMPPBuddy class]] && ((OTRXMPPBuddy *)object).askingForApproval) {
                return OTRAllPresenceSubscriptionRequestGroup;
            }
            if ([object isKindOfClass:[OTRBuddy class]])
            {
                OTRBuddy *buddy = (OTRBuddy *)object;
                if (!buddy.username.length) {
                    return nil;
                }
                // Hack to show "placeholder" items in list
                if (buddy.lastMessageId && buddy.lastMessageId.length == 0) {
                    return OTRConversationGroup;
                }
                id <OTRMessageProtocol> lastMessage = [buddy lastMessageWithTransaction:transaction];
                if (lastMessage) {
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
                id <OTRMessageProtocol> message1 = [thread1 lastMessageWithTransaction:transaction];
                id <OTRMessageProtocol> message2 = [thread2 lastMessageWithTransaction:transaction];
                
                // Assume nil dates indicate a lastMessageId of ""
                // indicating that we want to force to the top
                NSDate *date1 = [message1 messageDate];
                if (!date1) {
                    if (thread1.lastMessageIdentifier && thread1.lastMessageIdentifier.length == 0) {
                        date1 = [NSDate date];
                    } else {
                        date1 = [NSDate distantPast];
                    }
                }
                NSDate *date2 = [message2 messageDate];
                if (!date2) {
                    if (thread2.lastMessageIdentifier && thread2.lastMessageIdentifier.length == 0) {
                        date2 = [NSDate date];
                    } else {
                        date2 = [NSDate distantPast];
                    }
                }
                
                return [date2 compare:date1];
            }
        } else if ([group isEqualToString:OTRAllPresenceSubscriptionRequestGroup]) {
            if ([object1 isKindOfClass:[OTRXMPPBuddy class]] && [object2 isKindOfClass:[OTRXMPPBuddy class]]) {
                OTRXMPPBuddy *request1 = object1;
                OTRXMPPBuddy *request2 = object2;
                return [request2.displayName compare:request1.displayName];
            }
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    NSSet *whiteListSet = [NSSet setWithObjects:[OTRBuddy collection],[OTRXMPPRoom collection], nil];
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:whiteListSet];
    
    YapDatabaseAutoView *databaseView = [[YapDatabaseAutoView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"9"
                                                                      options:options];
    
    BOOL result = [database registerExtension:databaseView withName:OTRConversationDatabaseViewExtensionName];
    if (result)  {
        result = [self registerArchiveFilteredConversationsViewWithDatabase:database];
    }
    if (result) {
        result = [self registerBuddyFilteredConversationsViewWithDatabase:database];
    }
    return result;
}

+ (BOOL)registerAllAccountsDatabaseViewWithDatabase:(YapDatabase *)database
{
    YapDatabaseView *accountView = [database registeredExtension:OTRAllAccountDatabaseViewExtensionName];
    if (accountView) {
        return YES;
    }
    
    [YapDatabaseViewGrouping withObjectBlock:^NSString * _Nullable(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
        if ([collection isEqualToString:[OTRAccount collection]] && [object isKindOfClass:[OTRAccount class]])
        {
            OTRAccount *account = object;
            if (!account.username.length) {
                return nil;
            }
            return OTRAllAccountGroup;
        }
        
        return nil;
    }];
    
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
    
    YapDatabaseAutoView *databaseView = [[YapDatabaseAutoView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"2"
                                                                      options:options];
    
    return [database registerExtension:databaseView withName:OTRAllAccountDatabaseViewExtensionName];
}

+ (BOOL)registerFilteredChatViewWithDatabase:(YapDatabase *)database {
    YapDatabaseFilteredView *filteredView = [database registeredExtension:OTRFilteredChatDatabaseViewExtensionName];
    if (filteredView) {
        return YES;
    }
    YapDatabaseView *chatView = [database registeredExtension:OTRChatDatabaseViewExtensionName];
    if (!chatView) {
        return NO;
    }
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
        if ([object conformsToProtocol:@protocol(OTRMessageProtocol)]) {
            id<OTRMessageProtocol> message = object;
            BOOL shouldDisplay = [FileTransferManager shouldDisplayMessage:message transaction:transaction];
            return shouldDisplay;
        }
        return YES;
    }];
    filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:OTRChatDatabaseViewExtensionName filtering:filtering versionTag:@"6" options:options];
    return [database registerExtension:filteredView withName:OTRFilteredChatDatabaseViewExtensionName];
}

+ (BOOL)registerChatDatabaseViewWithDatabase:(YapDatabase *)database
{
    if ([database registeredExtension:OTRChatDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key, id object) {
        if ([object conformsToProtocol:@protocol(OTRMessageProtocol)])
        {
            id <OTRMessageProtocol> message = object;
            NSString *threadId = [message threadId];
            if (!threadId) {
                DDLogError(@"Message has no threadId! %@", message);
                return nil;
            } else {
                return threadId;
            }
        } else {
            DDLogError(@"Object in view does not conform to OTRMessageProtocol! %@", object);
            return nil;
        }
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([object1 conformsToProtocol:@protocol(OTRMessageProtocol)] && [object2 conformsToProtocol:@protocol(OTRMessageProtocol)]) {
            id <OTRMessageProtocol> message1 = (id <OTRMessageProtocol>)object1;
            id <OTRMessageProtocol> message2 = (id <OTRMessageProtocol>)object2;
            
            return [[message1 messageDate] compare:[message2 messageDate]];
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    NSSet *whitelist = [NSSet setWithObjects:[OTRBaseMessage collection],[OTRXMPPRoomMessage collection], nil];
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:whitelist];
    
    
    
    YapDatabaseAutoView *view = [[YapDatabaseAutoView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"1"
                                                              options:options];
    
    return [database registerExtension:view withName:OTRChatDatabaseViewExtensionName] && [self registerFilteredChatViewWithDatabase:database];
}

+ (BOOL)registerAllBuddiesDatabaseViewWithDatabase:(YapDatabase *)database
{
    if ([database registeredExtension:OTRAllBuddiesDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(YapDatabaseReadTransaction *transaction, NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRBuddy class]]) {
            
            //Checking to see if the buddy username is equal to the account username in order to remove 'self' buddy
            OTRBuddy *buddy = (OTRBuddy *)object;
            OTRAccount *account = [buddy accountWithTransaction:transaction];
            // Hack fix for buddies created without an account
            // There must be a race condition in the roster popualtion
            if (!account) {
                return nil;
            }
            // Filter out buddies with no username
            if (!buddy.username.length) {
                return nil;
            }
            if (![account.username isEqualToString:buddy.username]) {
                
                // Filter out buddies that are not really on our roster
                if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                    OTRXMPPBuddy *xmppBuddy = (OTRXMPPBuddy *)buddy;
                    if (xmppBuddy.trustLevel != BuddyTrustLevelRoster && !xmppBuddy.pendingApproval) {
                        return nil;
                    }
                }
                return OTRBuddyGroup;
            }
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction *transaction, NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        
        OTRBuddy *buddy1 = (OTRBuddy *)object1;
        OTRBuddy *buddy2 = (OTRBuddy *)object2;
        
        NSComparisonResult result = NSOrderedSame;
        
        if (buddy1.currentStatus == buddy2.currentStatus) {
            NSString *buddy1String = buddy1.username;
            NSString *buddy2String = buddy2.username;
            
            if ([buddy1.displayName length]) {
                buddy1String = buddy1.displayName;
            }
            
            if ([buddy2.displayName length]) {
                buddy2String = buddy2.displayName;
            }
            
            result = [buddy1String compare:buddy2String options:NSCaseInsensitiveSearch];
        }
        else if (buddy1.currentStatus < buddy2.currentStatus) {
            result = NSOrderedAscending;
        }
        else {
            result = NSOrderedDescending;
        }
        
        NSComparisonResult archiveSort = [@(buddy1.isArchived) compare:@(buddy2.isArchived)];
        if (archiveSort == NSOrderedSame) {
            return result;
        } else {
            return archiveSort;
        }
    }];
    
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseAutoView *view = [[YapDatabaseAutoView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"9"
                                                              options:options];
    
    return [database registerExtension:view withName:OTRAllBuddiesDatabaseViewExtensionName] && [self registerFilteredBuddiesViewWithDatabase:database];
}

+ (BOOL)registerFilteredBuddiesViewWithDatabase:(YapDatabase *)database {
    YapDatabaseFilteredView *filteredView = [database registeredExtension:OTRArchiveFilteredBuddiesName];
    if (filteredView) {
        return YES;
    }
    YapDatabaseView *buddiesView = [database registeredExtension:OTRAllBuddiesDatabaseViewExtensionName];
    if (!buddiesView) {
        return NO;
    }
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = NO;
    BOOL showArchived = NO;
    YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
        if ([object conformsToProtocol:@protocol(OTRThreadOwner)]) {
            id<OTRThreadOwner> threadOwner = object;
            BOOL isArchived = threadOwner.isArchived;
            return showArchived == isArchived;
        }
        return YES;
    }];
    filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:OTRAllBuddiesDatabaseViewExtensionName filtering:filtering versionTag:[NSUUID UUID].UUIDString options:options];
    return [database registerExtension:filteredView withName:OTRArchiveFilteredBuddiesName];
}

@end
