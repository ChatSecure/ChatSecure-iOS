//
//  OTRMessagesViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSQMessagesViewController.h"

@class OTRBroadcastGroup;

@interface OTRMessagesGroupViewController : JSQMessagesViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) OTRBroadcastGroup *broadcastGroup;

@end
