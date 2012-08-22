//
//  OTRSettingsManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
// 
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
#import "OTRSetting.h"

#ifdef CRITTERCISM_ENABLED
#define kOTRSettingKeyCrittercismOptIn @"kOTRSettingKeyCrittercismOptIn"
#endif

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
