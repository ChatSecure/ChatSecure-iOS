//
//  OTRNotificationPermissions.h
//  ChatSecure
//
//  Created by David Chiles on 10/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRNotificationPermissions : NSObject

+ (void)checkPermissions;
+ (bool)canSendNotifications;

@end
