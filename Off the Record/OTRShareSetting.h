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

#import "OTRSetting.h"

@interface OTRShareSetting : OTRSetting <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate,MFMessageComposeViewControllerDelegate>

@property (nonatomic,strong) id delegate;
@property (nonatomic, retain) NSURL *lastActionLink;


@end
