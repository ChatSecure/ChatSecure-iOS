//
//  OTRDoubleSettingDetailViewController.h
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
