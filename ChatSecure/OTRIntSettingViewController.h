//
//  OTRIntSettingViewController.h
//  Off the Record
//
//  Created by David on 2/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRSettingDetailViewController.h"
#import "OTRIntSetting.h"
@interface OTRIntSettingViewController : OTRSettingDetailViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSInteger newValue;
}


@property (nonatomic, retain) UILabel *descriptionLabel;
@property (nonatomic, retain) UITableView *valueTable;
@property (nonatomic, retain) UILabel *valueLabel;
@property (nonatomic, retain) OTRIntSetting *otrSetting;
@property (nonatomic, retain) NSIndexPath *selectedPath;

@end
