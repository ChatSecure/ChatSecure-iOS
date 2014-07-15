//
//  OTRListSettingViewController.h
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingDetailViewController.h"
#import "OTRListSetting.h"

@interface OTRListSettingViewController : OTRSettingDetailViewController <UITableViewDataSource,UITableViewDelegate>
{
    NSString * newValue;
    NSString * oldValue;
}

@property (nonatomic,strong) OTRListSetting * otrSetting;
@property (nonatomic,strong) NSIndexPath * selectedPath;
@property (nonatomic,strong) UITableView * valueTable;

@end
