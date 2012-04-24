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

@property (nonatomic, retain) OTRSetting *otrSetting;
@property (nonatomic, retain) UIBarButtonItem *saveButton;
- (void) save:(id)sender;

@end
