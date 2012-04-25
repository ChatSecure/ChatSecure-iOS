//
//  OTRSettingDetailViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRSetting.h"

@interface OTRSettingDetailViewController : UIViewController

@property (nonatomic, strong) OTRSetting *otrSetting;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
- (void) save:(id)sender;

@end
