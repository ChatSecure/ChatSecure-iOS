//
//  OTRDatabaseView.h
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import YapDatabase;

NS_ASSUME_NONNULL_BEGIN


//Extension Strings
/** Returns only Buddy threads with messages, not MUCs. Depends on OTRConversationDatabaseViewExtensionName */
extern NSString *OTRBuddyFilteredConversationsName;
/** Can filter on inbox vs archive. Depends on OTRConversationDatabaseViewExtensionName */
extern NSString *OTRArchiveFilteredConversationsName;
/** Can filter on inbox vs archive. Depends on OTRAllBuddiesDatabaseViewExtensionName */
extern NSString *OTRArchiveFilteredBuddiesName;

extern NSString *OTRConversationDatabaseViewExtensionName;
/** Right now only filters messages without a length */
extern NSString *OTRFilteredChatDatabaseViewExtensionName;
extern NSString *OTRChatDatabaseViewExtensionName;
extern NSString *OTRAllAccountDatabaseViewExtensionName;
extern NSString *OTRAllBuddiesDatabaseViewExtensionName;
extern NSString *OTRAllSubscriptionRequestsViewExtensionName;
extern NSString *OTRAllPushAccountInfoViewExtensionName;

// Group Strings
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


+ (BOOL)registerConversationDatabaseViewWithDatabase:(YapDatabase *)database;
+ (BOOL)registerArchiveFilteredConversationsViewWithDatabase:(YapDatabase *)database;
+ (BOOL)registerBuddyFilteredConversationsViewWithDatabase:(YapDatabase *)database;

+ (BOOL)registerAllAccountsDatabaseViewWithDatabase:(YapDatabase *)database;


/**
 Objects in this class are both OTRMessage and OTRXMPPRoomMessage. For OTRMessage they are grouped
 by buddyUniqueID. For OTRXMPPRoomMessage they are grouped by roomUniqueID. In both cases they are
 sorted by date.
 */
+ (BOOL)registerChatDatabaseViewWithDatabase:(YapDatabase *)database;

+ (BOOL)registerAllBuddiesDatabaseViewWithDatabase:(YapDatabase *)database;
+ (BOOL)registerFilteredBuddiesViewWithDatabase:(YapDatabase *)database;

@end
NS_ASSUME_NONNULL_END
