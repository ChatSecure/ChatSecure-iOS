//
//  OTRSettingsViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRViewSetting.h"
#import "OTRSettingsManager.h"
#import <MessageUI/MessageUI.h>

@interface OTRSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, OTRSettingDelegate, UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) UITableView *settingsTableView;
@property (nonatomic, retain) OTRSettingsManager *settingsManager;

@end
