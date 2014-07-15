//
//  OTRComposeViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy;
@class OTRComposeViewController;

@protocol OTRComposeViewControllerDelegate <NSObject>

- (void)controller:(OTRComposeViewController *)viewController didSelectBuddy:(OTRBuddy *)buddy;

@end

@interface OTRComposeViewController : UIViewController

@property (nonatomic, weak) id<OTRComposeViewControllerDelegate> delegate;

@end
