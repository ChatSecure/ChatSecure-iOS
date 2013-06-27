//
//  OTRSettingsManager.m
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

#import "OTRSettingsManager.h"
#import "OTRViewSetting.h"
#import "Strings.h"
#import "OTRSettingsGroup.h"
#import "OTRSetting.h"
#import "OTRBoolSetting.h"
#import "OTRViewSetting.h"
#import "OTRDoubleSetting.h"
#import "OTRFeedbackSetting.h"
#import "OTRConstants.h"
#import "OTRShareSetting.h"
#import "OTRLanguageSetting.h"
#import "OTRDonateSetting.h"
#import "OTRIntSetting.h"

@interface OTRSettingsManager(Private)
- (void) populateSettings;
@end

@implementation OTRSettingsManager
@synthesize settingsGroups, settingsDictionary;

- (void) dealloc
{
    settingsGroups = nil;
    settingsDictionary = nil;
}

- (id) init
{
    if (self = [super init])
    {
        settingsGroups = [NSMutableArray array];
        [self populateSettings];
    }
    return self;
}

- (void) populateSettings
{
    NSMutableDictionary *newSettingsDictionary = [NSMutableDictionary dictionary];
    // Leave this in for now
    OTRViewSetting *accountsViewSetting = [[OTRViewSetting alloc] initWithTitle:ACCOUNTS_STRING description:nil viewControllerClass:nil];
    OTRSettingsGroup *accountsGroup = [[OTRSettingsGroup alloc] initWithTitle:ACCOUNTS_STRING settings:[NSArray arrayWithObject:accountsViewSetting]];
    [settingsGroups addObject:accountsGroup];
    
    /*
    OTRDoubleSetting *fontSizeSetting = [[OTRDoubleSetting alloc] initWithTitle:FONT_SIZE_STRING description:FONT_SIZE_DESCRIPTION_STRING settingsKey:kOTRSettingKeyFontSize];
    fontSizeSetting.maxValue = 20;
    fontSizeSetting.minValue = 12;
    fontSizeSetting.numValues = 4;
    fontSizeSetting.defaultValue = [NSNumber numberWithInt:16];
    fontSizeSetting.isPercentage = NO;
    */
    
    OTRIntSetting * fontSizeSetting = [[OTRIntSetting alloc] initWithTitle:FONT_SIZE_STRING description:FONT_SIZE_DESCRIPTION_STRING settingsKey:kOTRSettingKeyFontSize];
    fontSizeSetting.maxValue = 20;
    fontSizeSetting.minValue = 12;
    fontSizeSetting.numValues = 4;
    fontSizeSetting.defaultValue = [NSNumber numberWithInt:16];

    [newSettingsDictionary setObject:fontSizeSetting forKey:kOTRSettingKeyFontSize];
    OTRBoolSetting *deletedDisconnectedConversations = [[OTRBoolSetting alloc] initWithTitle:DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING description:DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING settingsKey:kOTRSettingKeyDeleteOnDisconnect];
    [newSettingsDictionary setObject:deletedDisconnectedConversations forKey:kOTRSettingKeyDeleteOnDisconnect];
    OTRBoolSetting *showDisconnectionWarning = [[OTRBoolSetting alloc] initWithTitle:DISCONNECTION_WARNING_TITLE_STRING description:DISCONNECTION_WARNING_DESC_STRING settingsKey:kOTRSettingKeyShowDisconnectionWarning];
    showDisconnectionWarning.defaultValue = [NSNumber numberWithBool:YES];
    [newSettingsDictionary setObject:showDisconnectionWarning forKey:kOTRSettingKeyShowDisconnectionWarning];
    OTRSettingsGroup *chatSettingsGroup = [[OTRSettingsGroup alloc] initWithTitle:CHAT_STRING settings:[NSArray arrayWithObjects:fontSizeSetting, deletedDisconnectedConversations, showDisconnectionWarning, nil]];
    [settingsGroups addObject:chatSettingsGroup];
    
    
    OTRFeedbackSetting * feedbackViewSetting = [[OTRFeedbackSetting alloc] initWithTitle:SEND_FEEDBACK_STRING description:nil];
    feedbackViewSetting.imageName = @"18-envelope.png";
    
    OTRShareSetting * shareViewSetting = [[OTRShareSetting alloc] initWithTitle:SHARE_STRING description:nil];
    shareViewSetting.imageName = @"275-broadcast.png";
    
    OTRLanguageSetting * languageSetting = [[OTRLanguageSetting alloc]initWithTitle:LANGUAGE_STRING description:nil settingsKey:kOTRSettingKeyLanguage];
    languageSetting.imageName = @"globe.png";
    
    OTRDonateSetting *donateSetting = [[OTRDonateSetting alloc] initWithTitle:DONATE_STRING description:nil];
    donateSetting.imageName = @"29-heart.png";
    
    NSMutableArray *otherSettings = [NSMutableArray arrayWithCapacity:5];
    [otherSettings addObjectsFromArray:@[languageSetting,donateSetting, shareViewSetting,feedbackViewSetting]];
#ifdef CRITTERCISM_ENABLED
    OTRBoolSetting *crittercismSetting = [[OTRBoolSetting alloc] initWithTitle:CRITTERCISM_TITLE_STRING description:CRITTERCISM_DESCRIPTION_STRING settingsKey:kOTRSettingKeyCrittercismOptIn];
    [newSettingsDictionary setObject:crittercismSetting forKey:kOTRSettingKeyCrittercismOptIn];
    [otherSettings addObject:crittercismSetting];
#endif
    OTRSettingsGroup *otherGroup = [[OTRSettingsGroup alloc] initWithTitle:OTHER_STRING settings:otherSettings];
    [settingsGroups addObject:otherGroup];
    settingsDictionary = newSettingsDictionary;
}

- (OTRSetting*) settingAtIndexPath:(NSIndexPath*)indexPath
{
    OTRSettingsGroup *settingsGroup = [settingsGroups objectAtIndex:indexPath.section];
    return [settingsGroup.settings objectAtIndex:indexPath.row];
}

- (NSString*) stringForGroupInSection:(NSUInteger)section
{
    OTRSettingsGroup *settingsGroup = [settingsGroups objectAtIndex:section];
    return settingsGroup.title;
}

- (NSUInteger) numberOfSettingsInSection:(NSUInteger)section
{
    OTRSettingsGroup *settingsGroup = [settingsGroups objectAtIndex:section];
    return [settingsGroup.settings count];
}

+ (BOOL) boolForOTRSettingKey:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

+ (double) doubleForOTRSettingKey:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults doubleForKey:key];
}

+ (NSInteger) intForOTRSettingKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:key];
}

+ (float) floatForOTRSettingKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults floatForKey:key];
}

- (OTRSetting*) settingForOTRSettingKey:(NSString*)key {
    return [settingsDictionary objectForKey:key];
}

@end
