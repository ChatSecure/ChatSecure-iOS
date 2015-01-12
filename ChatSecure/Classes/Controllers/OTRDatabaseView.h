//
//  OTRDatabaseView.h
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YapDatabaseViewMappings.h"
#import "YapDatabaseView.h"

//Extension Strings
extern NSString *OTRConversationDatabaseViewExtensionName;
extern NSString *OTRChatDatabaseViewExtensionName;
extern NSString *OTRBroadcastChatDatabaseViewExtensionName;
extern NSString *OTRAllAccountDatabaseViewExtensionName;
extern NSString *OTRBuddyDatabaseViewExtensionName;
extern NSString *OTRGroupDatabaseViewExtensionName;
extern NSString *OTRContactByGroupDatabaseViewExtensionName;

extern NSString *OTRBuddyNameSearchDatabaseViewExtensionName;
extern NSString *OTRChatNameSearchDatabaseViewExtensionName;
extern NSString *OTRBroadcastChatNameSearchDatabaseViewExtensionName;

extern NSString *OTRAllBroadcastListDatabaseViewExtensionName;

extern NSString *OTRContactDatabaseViewExtensionName;
extern NSString *OTRAllBuddiesDatabaseViewExtensionName;
extern NSString *OTRAllSubscriptionRequestsViewExtensionName;
extern NSString *OTRAllPushAccountInfoViewExtensionName;
extern NSString *OTRUnreadMessagesViewExtensionName;

// Group Strins
extern NSString *OTRAllAccountGroup;
extern NSString *OTRAllGroupsGroup;
extern NSString *OTRConversationGroup;
extern NSString *OTRChatMessageGroup;
extern NSString *OTRBuddyGroupList;
extern NSString *OTRAllBroadcastGroupList;
extern NSString *OTRAllBuddiesGroupList;
extern NSMutableArray *OTRContactByGroupList;

extern NSString *OTRUnreadMessageGroup;
extern NSString *OTRAllPresenceSubscriptionRequestGroup;


extern NSString *OTRPushAccountGroup;
extern NSString *OTRPushDeviceGroup;
extern NSString *OTRPushTokenGroup;


@interface OTRDatabaseView : NSObject


+ (BOOL)registerAllBroadcastListDatabaseView;

+ (BOOL)registerContactByGroupDatabaseView;

+ (BOOL)registerConversationDatabaseView;

+ (BOOL)registerAllAccountsDatabaseView;

+ (BOOL)registerChatDatabaseView;

+ (BOOL)registerBroadcastChatDatabaseView;

+ (BOOL)registerGroupDatabaseView;

+ (BOOL)registerBuddyDatabaseView;

+ (BOOL)registerBuddyNameSearchDatabaseView;

+ (BOOL)registerChatNameSearchDatabaseView;

+ (BOOL)registerAllBuddiesDatabaseView;

+ (BOOL)registerContactDatabaseView;

+ (BOOL)registerAllSubscriptionRequestsView;

+ (BOOL)registerUnreadMessagesView;

+ (BOOL)registerPushView;
@end
