//
//  OTRNotificationPermissions.m
//  ChatSecure
//
//  Created by David Chiles on 10/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRNotificationPermissions.h"
#import "OTRUtilities.h"

static const UIUserNotificationType USER_NOTIFICATION_TYPES_REQUIRED = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;

@implementation OTRNotificationPermissions

+ (void)checkPermissions
{
    if (![self canSendNotifications]) {
        UIUserNotificationSettings* requestedSettings = [UIUserNotificationSettings settingsForTypes:USER_NOTIFICATION_TYPES_REQUIRED categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:requestedSettings];
    }
}

+ (bool)canSendNotifications
{
    UIUserNotificationSettings* notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    bool canSendNotifications = notificationSettings.types == USER_NOTIFICATION_TYPES_REQUIRED;
    
    return canSendNotifications;
}


@end
