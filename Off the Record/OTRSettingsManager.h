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
#define kOTRSettingKeyDeleteOnDisconnect @"kOTRSettingKeyDeleteOnDisconnect"
#define kOTRSettingKeyShowDisconnectionWarning @"kOTRSettingKeyShowDisconnectionWarning"
#define kOTRSettingUserAgreedToEULA @"kOTRSettingUserAgreedToEULA"
#define kOTRSettingAccountsKey @"kOTRSettingAccountsKey"

@interface OTRSettingsManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *settingsGroups;
@property (nonatomic, strong, readonly) NSDictionary *settingsDictionary;

- (OTRSetting*) settingAtIndexPath:(NSIndexPath*)indexPath;
- (NSString*) stringForGroupInSection:(NSUInteger)section;
- (NSUInteger) numberOfSettingsInSection:(NSUInteger)section;
- (OTRSetting*) settingForOTRSettingKey:(NSString*)key;

+ (BOOL) boolForOTRSettingKey:(NSString*)key;
+ (double) doubleForOTRSettingKey:(NSString*)key;

@end
