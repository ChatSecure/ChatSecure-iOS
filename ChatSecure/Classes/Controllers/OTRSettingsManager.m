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
#import "OTRSetting.h"
#import "OTRBoolSetting.h"
#import "OTRViewSetting.h"
#import "OTRDoubleSetting.h"
#import "OTRFeedbackSetting.h"
#import "OTRConstants.h"
#import "OTRShareSetting.h"
#import "OTRSettingsGroup.h"
#import "OTRLanguageSetting.h"
#import "OTRDonateSetting.h"
#import "OTRIntSetting.h"
#import "OTRCertificateSetting.h"
#import "OTRUtilities.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import <ChatSecureUIKit/ChatSecureUIKit-Swift.h>
@import ChatSecureCore;

#import "OTRUtilities.h"

@interface OTRSettingsManager ()
@end

@implementation OTRSettingsManager

- (instancetype) init
{
    if (self = [super init])
    {
        [self populateSettings];
    }
    return self;
}

- (void) populateSettings
{
    NSMutableArray<OTRSettingsGroup*> *settingsGroups = [NSMutableArray array];
    NSMutableDictionary *newSettingsDictionary = [NSMutableDictionary dictionary];
    // Leave this in for now
    OTRViewSetting *accountsViewSetting = [[OTRViewSetting alloc] initWithTitle:ACCOUNTS_STRING description:nil viewControllerClass:nil];
    OTRSettingsGroup *accountsGroup = [[OTRSettingsGroup alloc] initWithTitle:ACCOUNTS_STRING settings:@[accountsViewSetting]];
    [settingsGroups addObject:accountsGroup];
    
    OTRBoolSetting *deletedDisconnectedConversations = [[OTRBoolSetting alloc] initWithTitle:DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING
                                                                                 description:DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING
                                                                                 settingsKey:kOTRSettingKeyDeleteOnDisconnect];
    
    [newSettingsDictionary setObject:deletedDisconnectedConversations forKey:kOTRSettingKeyDeleteOnDisconnect];
    
    OTRCertificateSetting * certSetting = [[OTRCertificateSetting alloc] initWithTitle:PINNED_CERTIFICATES_STRING
                                                                           description:PINNED_CERTIFICATES_DESCRIPTION_STRING];
    
    certSetting.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (![OTRNotificationPermissions canSendNotifications] ||
        [PushController getPushPreference] != PushPreferenceEnabled) {
        OTRViewSetting *pushViewSetting = [[OTRViewSetting alloc] initWithTitle:CHATSECURE_PUSH_STRING description:nil viewControllerClass:[EnablePushViewController class]];
        pushViewSetting.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        OTRSettingsGroup *pushGroup = [[OTRSettingsGroup alloc] initWithTitle:PUSH_TITLE_STRING settings:@[pushViewSetting]];
        [settingsGroups addObject:pushGroup];
    }

    
    NSArray *chatSettings = @[deletedDisconnectedConversations];
    OTRSettingsGroup *chatSettingsGroup = [[OTRSettingsGroup alloc] initWithTitle:CHAT_STRING settings:chatSettings];
    [settingsGroups addObject:chatSettingsGroup];
    
    NSArray * securitySettings = @[certSetting];
    OTRSettingsGroup *securitySettingsGroup = [[OTRSettingsGroup alloc] initWithTitle:SECURITY_STRING settings:securitySettings];
    [settingsGroups addObject:securitySettingsGroup];
    
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
    [settingsGroups addObject:otherGroup];
    _settingsDictionary = newSettingsDictionary;
    _settingsGroups = settingsGroups;
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

- (nullable NSIndexPath *)indexPathForSetting:(OTRSetting *)setting
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

- (nullable OTRSetting*) settingForOTRSettingKey:(NSString*)key {
    return [self.settingsDictionary objectForKey:key];
}

@end
