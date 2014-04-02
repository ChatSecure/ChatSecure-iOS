//
//  OTRDatabaseView.h
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YapDatabaseView;

extern NSString const *OTRConversationGroup;
extern NSString const *OTRConversationDatabaseViewExtensionName;

extern NSString const *OTRAllAccountGroup;
extern NSString const *OTRAllAccountDatabaseViewExtensionName;

@interface OTRDatabaseView : NSObject


+ (YapDatabaseView *)conversationDatabaseView;

+ (YapDatabaseView *)allAccountsDatabaseView;

@end
