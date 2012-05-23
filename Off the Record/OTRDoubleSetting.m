//
//  OTRDoubleSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRDoubleSetting.h"
#import "OTRDoubleSettingViewController.h"

@implementation OTRDoubleSetting
@synthesize doubleValue, minValue, maxValue, numValues, isPercentage;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        self.action = @selector(editValue);
        self.defaultValue = [NSNumber numberWithDouble:0.0];
        self.isPercentage = NO;
    }
    return self;
}

- (void) editValue {
    if(self.delegate && [self.delegate conformsToProtocol:@protocol(OTRSettingDelegate)]) {
        [self.delegate otrSetting:self showDetailViewControllerClass:[OTRDoubleSettingViewController class]];
    }
}

- (void) setDoubleValue:(double)value {
    [self setValue:[NSNumber numberWithDouble:value]];
    if(self.delegate && [self.delegate conformsToProtocol:@protocol(OTRSettingDelegate)]) {
        [self.delegate refreshView];
    }
}

- (double) doubleValue {
    if (![self value]) 
    {
        self.value = self.defaultValue;
    } 
    return [[self value] doubleValue];
}

- (NSString*) stringValue {
    NSString *text = nil;
    if(isPercentage) 
    {
        text = [NSString stringWithFormat:@"%d%%", (int)([self doubleValue] * 100)];
    }
    else 
    {
        text = [NSString stringWithFormat:@"%.02f", [self doubleValue]];
    }
    return text;
}

@end
