//
//  OTRDoubleSettingDetailViewController.m
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

#import "OTRDoubleSettingViewController.h"
@import OTRAssets;


@interface OTRDoubleSettingViewController (Private)
- (void) setTextForValueLabel;
- (NSString*) stringForValue:(double)value;
- (int) indexForValue:(double)value;
@end

@implementation OTRDoubleSettingViewController
@synthesize valueLabel, valueTable, otrSetting, descriptionLabel, selectedPath;

- (void) dealloc {
    self.valueLabel = nil;
    self.valueTable = nil;
    self.descriptionLabel = nil;
    self.otrSetting = nil;
}

- (id) init {
    if (self = [super init]) {
        self.valueLabel = [[UILabel alloc] init];
        self.descriptionLabel = [[UILabel alloc] init];
        self.valueTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.valueTable.delegate = self;
        self.valueTable.dataSource = self;
    }
    return self;
}

- (void) loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    self.valueTable.backgroundColor = [UIColor clearColor];
    self.valueTable.backgroundView = nil;
    self.valueTable.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.backgroundColor = [UIColor clearColor];
    self.valueLabel.font = [UIFont boldSystemFontOfSize:18.0];
    self.valueLabel.shadowColor = [UIColor whiteColor];
    self.valueLabel.shadowOffset = CGSizeMake(0, -1);
    self.valueTable.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.backgroundColor = [UIColor clearColor];
    self.descriptionLabel.textColor = [UIColor darkGrayColor];
    self.descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [self.view addSubview:valueLabel];
    [self.view addSubview:valueTable];
    [self.view addSubview:descriptionLabel];
}

- (CGPoint) roundedCenterPoint:(CGPoint) pt {
    return CGPointMake(round(pt.x), round(pt.y));
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setTextForValueLabel];
    self.descriptionLabel.text = otrSetting.settingDescription;
    
    
    double widthFraction = .8;
    CGFloat tableWidth = self.view.frame.size.width * widthFraction;
    CGFloat tableXOrigin = self.view.frame.size.width * (1-widthFraction)/2;

    CGFloat valueLabelWidth = [self textSizeForLabel:valueLabel].width + 20;
    CGFloat descriptionLabelWdith = [self textSizeForLabel:descriptionLabel].width + 20;
    valueLabel.frame = CGRectMake(self.view.frame.size.width/2 - valueLabelWidth/2, 20, valueLabelWidth, 50);
    CGFloat descriptionYOrigin = valueLabel.frame.origin.y + valueLabel.frame.size.height + 10;
    descriptionLabel.frame = CGRectMake(self.view.frame.size.width/2 - descriptionLabelWdith/2, descriptionYOrigin, descriptionLabelWdith, 50);
    CGFloat tableYOrigin = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height + 20;
    valueTable.frame = CGRectMake(tableXOrigin, tableYOrigin, tableWidth, self.view.frame.size.height - tableYOrigin);

    newValue = otrSetting.doubleValue;
    
    int index = [self indexForValue:otrSetting.doubleValue];
    self.selectedPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.valueTable selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:valueTable didSelectRowAtIndexPath:selectedPath];
    
    valueLabel.frame  = CGRectIntegral(valueLabel.frame);
    valueLabel.center = [self roundedCenterPoint:valueLabel.center];
    descriptionLabel.frame  = CGRectIntegral(descriptionLabel.frame);
    descriptionLabel.center = [self roundedCenterPoint:descriptionLabel.center];
}

- (void) save:(id)sender {
    otrSetting.doubleValue = newValue;
    [super save:sender];
}

- (void) setTextForValueLabel {
    self.valueLabel.text = [NSString stringWithFormat:@"%@: %@\t%@: %@", OLD_STRING(), [self stringForValue:otrSetting.doubleValue], NEW_STRING(), [self stringForValue:newValue]];
}

- (NSString*) stringForValue:(double)value {
    if (otrSetting.isPercentage) {
        return [NSString stringWithFormat:@"%d%%", (int)(value * 100)];
    } else {
        return [NSString stringWithFormat:@"%.02f", value];
    }
}

- (double) valueForRow:(int)row 
{
    double range = otrSetting.maxValue - otrSetting.minValue;
    double increment = range / otrSetting.numValues;
    return otrSetting.minValue + (row*increment);
}

- (int) indexForValue:(double)value 
{
    int index = ((value / (otrSetting.maxValue - otrSetting.minValue))*otrSetting.numValues) - 1;
    //int index = ((value - otrSetting.minValue) / otrSetting.numValues) + 1;
    return index;
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return otrSetting.numValues + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    double value = [self valueForRow:(int)indexPath.row];
    cell.textLabel.text = [self stringForValue:value];
    if ([indexPath isEqual:selectedPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}


#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedPath = indexPath;
    newValue = [self valueForRow:(int)indexPath.row];
    [self setTextForValueLabel];
    [self.valueTable reloadData];
    [self.valueTable selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

/*- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.valueTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}*/

@end
