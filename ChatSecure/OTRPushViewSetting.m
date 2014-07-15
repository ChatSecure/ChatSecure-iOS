//
//  OTRPushViewSetting.m
//  Off the Record
//
//  Created by David Chiles on 4/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushViewSetting.h"
#import "OTRAccountsManager.h"
#import "OTRPushAccountViewController.h"
#import "OTRPushAccountLoginViewController.h"

#import "OTRDatabaseManager.h"

@implementation OTRPushViewSetting

- (id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription {
    self = [super initWithTitle:newTitle description:newDescription viewControllerClass:nil];
    return self;
}

- (void)showView
{
    Class class;
    if ([OTRAccountsManager defaultPushAccount]) {
        class = [OTRPushAccountViewController class];
    }
    else {
        class = [OTRPushAccountLoginViewController class];
    }
    
    [self.delegate otrSetting:self showDetailViewControllerClass:class];
    
}

@end
