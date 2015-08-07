//
//  OTRNotificationController.h
//  ChatSecure
//
//  Created by David Chiles on 12/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRNotificationController : NSObject

@property (nonatomic) BOOL enabled;

- (void)start;
- (void)stop;

- (void)showAccountConnectingNotificationWithAccountName:(NSString *)accountName;


+ (instancetype)sharedInstance;

@end
