//
//  OTRDoubleSettingDetailViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRDoubleSettingViewController.h"
#import "Strings.h"

@interface OTRDoubleSettingViewController ()

@end

@implementation OTRDoubleSettingViewController
@synthesize valueLabel, valuePicker, otrSetting;

- (void) dealloc {
    self.valueLabel = nil;
    self.valuePicker = nil;
}

- (id) init {
    if (self = [super init]) {
        self.valueLabel = [[UILabel alloc] init];
        self.valuePicker = [[UIPickerView alloc] init];
        self.valuePicker.delegate = self;
        self.valuePicker.dataSource = self;
    }
    return self;
}

- (void) loadView {
    [super loadView];
    [self.view addSubview:valueLabel];
    [self.view addSubview:valuePicker];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    valueLabel.frame = CGRectMake(0, 0, 200, 50);
    valuePicker.frame = CGRectMake(0, 100, 200, 200);
    newValue = otrSetting.doubleValue;
    [self setTextForValueLabel];
    [valuePicker selectRow:[self indexForValue:otrSetting.doubleValue]+1 inComponent:0 animated:NO];
}

- (void) save:(id)sender {
    otrSetting.doubleValue = newValue;
    [super save:sender];
}

- (void) setTextForValueLabel {
    self.valueLabel.text = [NSString stringWithFormat:@"%@: %@\t%@: %@", OLD_STRING, [self stringForValue:otrSetting.doubleValue], NEW_STRING, [self stringForValue:newValue]];
}

- (NSString*) stringForValue:(double)value {
    if (otrSetting.isPercentage) {
        return [NSString stringWithFormat:@"%d%%", (int)(value * 100)];
    } else {
        return [NSString stringWithFormat:@"%.02f", value];
    }
}

#pragma mark UIPickerViewDataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return otrSetting.numValues + 1;
}

- (double) valueForRow:(int)row {
    double range = otrSetting.maxValue - otrSetting.minValue;
    double increment = range / otrSetting.numValues;
    return otrSetting.minValue + (row*increment);
}

- (int) indexForValue:(double)value {
    int index = (value - otrSetting.minValue) / otrSetting.numValues;
    return index;
}

#pragma mark UIPickerViewDelegate methods

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    double value = [self valueForRow:row];
    return [self stringForValue:value];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    newValue = [self valueForRow:row];
    [self setTextForValueLabel];
}

@end
