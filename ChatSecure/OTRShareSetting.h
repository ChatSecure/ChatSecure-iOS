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

@class OTRShareSetting;

@protocol OTRShareSettingDelegate <NSObject>

- (void)didSelectShareSetting:(OTRShareSetting *)shareSetting;

@end

@interface OTRShareSetting : OTRViewSetting

@property (nonatomic, weak) id <OTRShareSettingDelegate> delegate;
@property (nonatomic, strong) NSURL *lastActionLink;


@end
