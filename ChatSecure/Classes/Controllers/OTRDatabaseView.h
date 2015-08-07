//
//  OTRDatabaseView.h
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YapDatabase;


//Extension Strings
extern NSString *OTRConversationDatabaseViewExtensionName;
extern NSString *OTRChatDatabaseViewExtensionName;
extern NSString *OTRAllAccountDatabaseViewExtensionName;
extern NSString *OTRBuddyNameSearchDatabaseViewExtensionName;
extern NSString *OTRAllBuddiesDatabaseViewExtensionName;
extern NSString *OTRAllSubscriptionRequestsViewExtensionName;
extern NSString *OTRAllPushAccountInfoViewExtensionName;
extern NSString *OTRUnreadMessagesViewExtensionName;

// Group Strins
extern NSString *OTRAllAccountGroup;
extern NSString *OTRConversationGroup;
extern NSString *OTRChatMessageGroup;
extern NSString *OTRBuddyGroup;
extern NSString *OTRUnreadMessageGroup;
extern NSString *OTRAllPresenceSubscriptionRequestGroup;

extern NSString *OTRPushAccountGroup;
extern NSString *OTRPushDeviceGroup;
extern NSString *OTRPushTokenGroup;

@interface OTRDatabaseView : NSObject


+ (BOOL)registerConversationDatabaseView;

+ (BOOL)registerAllAccountsDatabaseView;

+ (BOOL)registerChatDatabaseView;

+ (BOOL)registerBuddyNameSearchDatabaseView;

+ (BOOL)registerAllBuddiesDatabaseView;

+ (BOOL)registerAllSubscriptionRequestsView;

+ (BOOL)registerUnreadMessagesView;

@end
