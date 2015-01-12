//
//  OTRMessagesViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSQMessagesViewController.h"

@class OTRBuddy, OTRMessage;

@interface OTRMessagesViewController : JSQMessagesViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) OTRBuddy *buddy;
@property (nonatomic, strong) OTRMessage *message;
@property (nonatomic) BOOL autoScroll;


@end
