//
//  OTRNotificationPermissions.m
//  ChatSecure
//
//  Created by David Chiles on 10/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRNotificationPermissions.h"
#import "OTRUtilities.h"

@implementation OTRNotificationPermissions

+ (bool)canSendNotifications
{
    UIUserNotificationSettings* notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    return notificationSettings.types != UIUserNotificationTypeNone;
}

@end
