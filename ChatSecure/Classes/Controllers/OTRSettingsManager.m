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
@import OTRAssets;
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
#import "OTRCertificateSetting.h"
#import "OTRUtilities.h"
#import "OTRFingerprintSetting.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

#import "OTRUtilities.h"

@interface OTRSettingsManager ()

@property (nonatomic, strong) NSMutableArray *settingsGroups;
@property (nonatomic, strong) NSDictionary *settingsDictionary;

- (void) populateSettings;
@end

@implementation OTRSettingsManager

- (id) init
{
    if (self = [super init])
    {
        [self populateSettings];
    }
    return self;
}

- (void) populateSettings
{
    self.settingsGroups = [NSMutableArray array];
    NSMutableDictionary *newSettingsDictionary = [NSMutableDictionary dictionary];
    // Leave this in for now
    OTRViewSetting *accountsViewSetting = [[OTRViewSetting alloc] initWithTitle:ACCOUNTS_STRING description:nil viewControllerClass:nil];
    OTRSettingsGroup *accountsGroup = [[OTRSettingsGroup alloc] initWithTitle:ACCOUNTS_STRING settings:[NSArray arrayWithObject:accountsViewSetting]];
    [self.settingsGroups addObject:accountsGroup];
    
    OTRBoolSetting *deletedDisconnectedConversations = [[OTRBoolSetting alloc] initWithTitle:DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING
                                                                                 description:DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING
                                                                                 settingsKey:kOTRSettingKeyDeleteOnDisconnect];
    
    [newSettingsDictionary setObject:deletedDisconnectedConversations forKey:kOTRSettingKeyDeleteOnDisconnect];
    
    OTRBoolSetting *opportunisticOtrSetting = [[OTRBoolSetting alloc] initWithTitle:OPPORTUNISTIC_OTR_SETTING_TITLE
                                                                        description:OPPORTUNISTIC_OTR_SETTING_DESCRIPTION
                                                                        settingsKey:kOTRSettingKeyOpportunisticOtr];
    opportunisticOtrSetting.defaultValue = @(YES);
    [newSettingsDictionary setObject:opportunisticOtrSetting forKey:kOTRSettingKeyOpportunisticOtr];
    
    OTRCertificateSetting * certSetting = [[OTRCertificateSetting alloc] initWithTitle:PINNED_CERTIFICATES_STRING
                                                                           description:PINNED_CERTIFICATES_DESCRIPTION_STRING];
    
    certSetting.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    OTRFingerprintSetting * fingerprintSetting = [[OTRFingerprintSetting alloc] initWithTitle:OTR_FINGERPRINTS_STRING
                                                                                  description:OTR_FINGERPRINTS_SUBTITLE_STRING];
    fingerprintSetting.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    
    if (![OTRNotificationPermissions canSendNotifications] ||
        [PushController getPushPreference] != PushPreferenceEnabled) {
        OTRViewSetting *pushViewSetting = [[OTRViewSetting alloc] initWithTitle:CHATSECURE_PUSH_STRING description:nil viewControllerClass:[EnablePushViewController class]];
        pushViewSetting.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        OTRSettingsGroup *pushGroup = [[OTRSettingsGroup alloc] initWithTitle:PUSH_TITLE_STRING settings:@[pushViewSetting]];
        [self.settingsGroups addObject:pushGroup];
    }

    
    NSArray *chatSettings;
    NSArray * securitySettings;
    
    
    chatSettings = [NSArray arrayWithObjects:deletedDisconnectedConversations, nil];
    
    OTRSettingsGroup *chatSettingsGroup = [[OTRSettingsGroup alloc] initWithTitle:CHAT_STRING settings:chatSettings];
    [self.settingsGroups addObject:chatSettingsGroup];
    
    securitySettings = @[opportunisticOtrSetting,certSetting,fingerprintSetting];
    OTRSettingsGroup *securitySettingsGroup = [[OTRSettingsGroup alloc] initWithTitle:SECURITY_STRING settings:securitySettings];
    [self.settingsGroups addObject:securitySettingsGroup];
    
    OTRFeedbackSetting * feedbackViewSetting = [[OTRFeedbackSetting alloc] initWithTitle:SEND_FEEDBACK_STRING description:nil];
    feedbackViewSetting.imageName = @"18-envelope.png";
    
    OTRShareSetting * shareViewSetting = [[OTRShareSetting alloc] initWithTitle:SHARE_STRING description:nil];
    shareViewSetting.imageName = @"275-broadcast.png";
    
    OTRLanguageSetting * languageSetting = [[OTRLanguageSetting alloc]initWithTitle:LANGUAGE_STRING description:nil settingsKey:kOTRSettingKeyLanguage];
    languageSetting.imageName = @"globe.png";
    [newSettingsDictionary setObject:languageSetting forKey:kOTRSettingKeyLanguage];
    
    OTRDonateSetting *donateSetting = [[OTRDonateSetting alloc] initWithTitle:DONATE_STRING description:nil];
    donateSetting.imageName = @"29-heart.png";
    
    NSMutableArray *otherSettings = [NSMutableArray arrayWithCapacity:5];
    [otherSettings addObjectsFromArray:@[languageSetting,donateSetting, shareViewSetting,feedbackViewSetting]];
    OTRSettingsGroup *otherGroup = [[OTRSettingsGroup alloc] initWithTitle:OTHER_STRING settings:otherSettings];
    [self.settingsGroups addObject:otherGroup];
    self.settingsDictionary = newSettingsDictionary;
}

- (OTRSetting*) settingAtIndexPath:(NSIndexPath*)indexPath
{
    OTRSettingsGroup *settingsGroup = [self.settingsGroups objectAtIndex:indexPath.section];
    return [settingsGroup.settings objectAtIndex:indexPath.row];
}

- (NSString*) stringForGroupInSection:(NSUInteger)section
{
    OTRSettingsGroup *settingsGroup = [self.settingsGroups objectAtIndex:section];
    return settingsGroup.title;
}

- (NSUInteger) numberOfSettingsInSection:(NSUInteger)section
{
    OTRSettingsGroup *settingsGroup = [self.settingsGroups objectAtIndex:section];
    return [settingsGroup.settings count];
}

- (NSIndexPath *)indexPathForSetting:(OTRSetting *)setting
{
    __block NSIndexPath *indexPath = nil;
    [self.settingsGroups enumerateObjectsUsingBlock:^(OTRSettingsGroup *group, NSUInteger idx, BOOL *stop) {
        NSUInteger row = [group.settings indexOfObject:setting];
        if (row != NSNotFound) {
            indexPath = [NSIndexPath indexPathForItem:row inSection:idx];
            *stop = YES;
        }
    }];
    return indexPath;
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
    return [self.settingsDictionary objectForKey:key];
}

@end
