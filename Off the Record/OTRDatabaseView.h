//
//  OTRDatabaseView.h
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YapDatabaseView;

extern NSString *OTRConversationGroup;
extern NSString *OTRConversationDatabaseViewExtensionName;

extern NSString *OTRAllAccountGroup;
extern NSString *OTRAllAccountDatabaseViewExtensionName;

@interface OTRDatabaseView : NSObject


+ (void)registerConversationDatabaseView;

+ (void)registerAllAccountsDatabaseView;

@end
