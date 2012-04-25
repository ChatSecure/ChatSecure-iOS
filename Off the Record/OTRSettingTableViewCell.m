//
//  OTRSettingTableViewself.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingTableViewCell.h"
#import "OTRBoolSetting.h"
#import "OTRViewSetting.h"
#import "OTRDoubleSetting.h"

@implementation OTRSettingTableViewCell
@synthesize otrSetting;


- (void) setOtrSetting:(OTRSetting *)setting {
    self.textLabel.text = setting.title;
    self.detailTextLabel.text = setting.description;
    if(setting.imageName)
    {
        self.imageView.image = [UIImage imageNamed:setting.imageName];
    }
    else 
    {
        self.imageView.image = nil;
    }
    
    UIView *accessoryView = nil;
    if ([setting isKindOfClass:[OTRBoolSetting class]]) {
        OTRBoolSetting *boolSetting = (OTRBoolSetting*)setting;
        UISwitch *boolSwitch = nil;
        BOOL animated;
        if (otrSetting == setting) {
            boolSwitch = (UISwitch*)self.accessoryView;
            animated = YES;
        } else {
            boolSwitch = [[UISwitch alloc] init];
            [boolSwitch addTarget:boolSetting action:boolSetting.action forControlEvents:UIControlEventValueChanged];
            animated = NO;
        }
        [boolSwitch setOn:[boolSetting enabled] animated:animated];
        accessoryView = boolSwitch;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    } 
    else if ([setting isKindOfClass:[OTRViewSetting class]])
    {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else if ([setting isKindOfClass:[OTRDoubleSetting class]]) 
    {
        OTRDoubleSetting *doubleSetting = (OTRDoubleSetting*)setting;
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
        valueLabel.backgroundColor = [UIColor clearColor];
        valueLabel.text = doubleSetting.stringValue;
        accessoryView = valueLabel;
    }
    self.accessoryView = accessoryView;
    otrSetting = setting;
}

@end
