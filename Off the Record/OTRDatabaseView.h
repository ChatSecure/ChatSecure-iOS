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

extern NSString *OTRConversationGroup;
extern NSString *OTRConversationDatabaseViewExtensionName;
extern NSString *OTRChatDatabaseViewExtensionName;

extern NSString *OTRAllAccountGroup;
extern NSString *OTRAllAccountDatabaseViewExtensionName;
extern NSString *OTRChatMessageGroup;

@interface OTRDatabaseView : NSObject


+ (void)registerConversationDatabaseView;

+ (void)registerAllAccountsDatabaseView;

+ (void)registerChatDatabaseViewWithBuddyUniqueId:(NSString *)buddyUniqueId;

@end
