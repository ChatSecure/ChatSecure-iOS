//
//  OTRSettingTableViewself.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRSettingTableViewCell.h"
#import "OTRBoolSetting.h"
#import "OTRViewSetting.h"
#import "OTRDoubleSetting.h"
#import "OTRIntSetting.h"
@import OTRAssets;

@implementation OTRSettingTableViewCell
@synthesize otrSetting;

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.detailTextLabel.numberOfLines = 0;
    }
    return self;
}

- (void) setOtrSetting:(OTRSetting *)setting {
    self.textLabel.text = setting.title;
    self.detailTextLabel.text = setting.settingDescription;
    if(setting.imageName)
    {
        self.imageView.image = [UIImage imageNamed:setting.imageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
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
            [boolSwitch addTarget:boolSetting action:@selector(toggle) forControlEvents:UIControlEventValueChanged];
            animated = NO;
        }
        [boolSwitch setOn:[boolSetting enabled] animated:animated];
        accessoryView = boolSwitch;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    } 
    else if ([setting isKindOfClass:[OTRViewSetting class]])
    {
        self.accessoryType = ((OTRViewSetting *)setting).accessoryType;
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
    else if ([setting isKindOfClass:[OTRIntSetting class]])
    {
        OTRIntSetting * intSetting = (OTRIntSetting*)setting;
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
        valueLabel.backgroundColor = [UIColor clearColor];
        valueLabel.text = intSetting.stringValue;
        accessoryView = valueLabel;
    }
    self.accessoryView = accessoryView;
    otrSetting = setting;
}

@end
