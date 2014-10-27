//
//  OTRShareSetting.h
//  Off the Record
//
//  Created by David on 11/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Twitter/Twitter.h>
#import <MessageUI/MessageUI.h>
#import "OTRViewSetting.h"

#import "OTRSetting.h"

@interface OTRShareSetting : OTRViewSetting <UIWebViewDelegate, MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>

@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NSURL *lastActionLink;


@end
