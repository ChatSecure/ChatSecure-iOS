//
//  OTRDoubleSettingDetailViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingDetailViewController.h"
#import "OTRDoubleSetting.h"

@interface OTRDoubleSettingViewController : OTRSettingDetailViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
    double newValue;
}

@property (nonatomic, retain) UIPickerView *valuePicker;
@property (nonatomic, retain) UILabel *valueLabel;
@property (nonatomic, retain) OTRDoubleSetting *otrSetting;

@end
