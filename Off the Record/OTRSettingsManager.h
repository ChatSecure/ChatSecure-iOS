//
//  OTRSettingsManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRSetting.h"

#ifdef CRITTERCISM_ENABLED
#define CRITTERCISM_OPT_IN @"CRITTERCISM_OPT_IN"
#endif

@interface OTRSettingsManager : NSObject

@property (nonatomic, readonly) NSMutableArray *settingsGroups;

- (OTRSetting*) settingAtIndexPath:(NSIndexPath*)indexPath;
- (NSString*) stringForGroupInSection:(NSUInteger)section;
- (NSUInteger) numberOfSettingsInSection:(NSUInteger)section;

@end
