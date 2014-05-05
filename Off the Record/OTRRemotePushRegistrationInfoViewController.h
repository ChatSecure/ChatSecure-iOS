//
//  OTRRemotePushRegistrationInfoViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTRRemotePushRegistrationInfoViewController : UIViewController

- (void)successfullRegistration:(NSNotification *)notification;
- (void)failedToRegister:(NSNotification *)notification;

@end
