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


extern NSString *OTRConversationDatabaseViewExtensionName;
extern NSString *OTRChatDatabaseViewExtensionName;
extern NSString *OTRAllAccountDatabaseViewExtensionName;
extern NSString *OTRBuddyDatabaseViewExtensionName;

extern NSString *OTRAllAccountGroup;
extern NSString *OTRConversationGroup;
extern NSString *OTRChatMessageGroup;
extern NSString *OTRBuddyGroup;

@interface OTRDatabaseView : NSObject


+ (BOOL)registerConversationDatabaseView;

+ (BOOL)registerAllAccountsDatabaseView;

+ (BOOL)registerChatDatabaseView;

+ (BOOL)registerBuddyDatabaseView;

@end
