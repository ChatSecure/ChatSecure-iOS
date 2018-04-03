//
//  OTRIntSettingViewController.m
//  Off the Record
//
//  Created by David on 2/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRIntSettingViewController.h"
@import OTRAssets;


@interface OTRIntSettingViewController (Private)
- (void) setTextForValueLabel;
- (NSString*) stringForValue:(NSInteger)value;
- (int) indexForValue:(NSInteger)value;

@end

@implementation OTRIntSettingViewController

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
    newValue = otrSetting.intValue;
    [self setTextForValueLabel];
    self.descriptionLabel.text = otrSetting.settingDescription;
    
    [self resizeDescriptionLabel];
    
    int index = [self indexForValue:otrSetting.intValue];
    self.selectedPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.valueTable selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:valueTable didSelectRowAtIndexPath:selectedPath];
}

-(void)resizeDescriptionLabel
{
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
    valueLabel.frame  = CGRectIntegral(valueLabel.frame);
    valueLabel.center = [self roundedCenterPoint:valueLabel.center];
    
    descriptionLabel.frame  = CGRectIntegral(descriptionLabel.frame);
    descriptionLabel.center = [self roundedCenterPoint:descriptionLabel.center];
    
}
- (void) save:(id)sender {
    otrSetting.intValue = newValue;
    [super save:sender];
}

- (void) setTextForValueLabel {
    self.valueLabel.text = [NSString stringWithFormat:@"%@: %@\t%@: %@", OLD_STRING(), [self stringForValue:otrSetting.intValue], NEW_STRING(), [self stringForValue:newValue]];
    self.descriptionLabel.font = [UIFont systemFontOfSize:newValue];
    [self resizeDescriptionLabel];
}

- (NSString*) stringForValue:(NSInteger)value {
    return [NSString stringWithFormat:@"%d", (int)value];
}

- (NSInteger) valueForRow:(int)row
{
    NSInteger range = otrSetting.maxValue - otrSetting.minValue;
    NSInteger increment = range / otrSetting.numValues;
    return otrSetting.minValue + (row*increment);
}

- (int) indexForValue:(NSInteger)value
{
    int index = (int)(value - otrSetting.minValue)/((otrSetting.maxValue - otrSetting.minValue)/otrSetting.numValues);
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
    NSInteger value = [self valueForRow:(int)indexPath.row];
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

