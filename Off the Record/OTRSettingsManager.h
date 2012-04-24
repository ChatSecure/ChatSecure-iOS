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
#define kOTRSettingKeyCrittercismOptIn @"kOTRSettingKeyCrittercismOptIn"
#endif

#define kOTRSettingKeyAllowSelfSignedSSL @"kOTRSettingKeyAllowSelfSignedSSL"
#define kOTRSettingKeyAllowSSLHostNameMismatch @"kOTRSettingKeyAllowSSLHostNameMismatch"

#define kOTRSettingKeyFontSize @"kOTRSettingKeyFontSize"

@interface OTRSettingsManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *settingsGroups;

- (OTRSetting*) settingAtIndexPath:(NSIndexPath*)indexPath;
- (NSString*) stringForGroupInSection:(NSUInteger)section;
- (NSUInteger) numberOfSettingsInSection:(NSUInteger)section;

+ (BOOL) boolForOTRSettingKey:(NSString*)key;
+ (double) doubleForOTRSettingKey:(NSString*)key;

@end
