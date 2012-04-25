//
//  OTRDoubleSettingDetailViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingDetailViewController.h"
#import "OTRDoubleSetting.h"

@interface OTRDoubleSettingViewController : OTRSettingDetailViewController <UITableViewDelegate, UITableViewDataSource>
{
    double newValue;
}

@property (nonatomic, retain) UILabel *descriptionLabel;
@property (nonatomic, retain) UITableView *valueTable;
@property (nonatomic, retain) UILabel *valueLabel;
@property (nonatomic, retain) OTRDoubleSetting *otrSetting;
@property (nonatomic, retain) NSIndexPath *selectedPath;

@end
