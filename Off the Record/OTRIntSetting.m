//
//  OTRIntSetting.m
//  Off the Record
//
//  Created by David on 2/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRIntSetting.h"
#import "OTRIntSettingViewController.h"

@implementation OTRIntSetting

@synthesize intValue, minValue, maxValue, numValues;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        self.action = @selector(editValue);
        self.defaultValue = [NSNumber numberWithInt:0];
    }
    return self;
}

- (void) editValue {
    if(self.delegate && [self.delegate conformsToProtocol:@protocol(OTRSettingDelegate)]) {
        [self.delegate otrSetting:self showDetailViewControllerClass:[OTRIntSettingViewController class]];
    }
}

- (void) setIntValue:(NSInteger)value {
    [self setValue:[NSNumber numberWithInt:value]];
    if(self.delegate && [self.delegate conformsToProtocol:@protocol(OTRSettingDelegate)]) {
        [self.delegate refreshView];
    }
}

- (NSInteger) intValue {
    if (![self value])
    {
        self.value = self.defaultValue;
    }
    return [[self value] intValue];
}

- (NSString*) stringValue {
    NSString *text = [NSString stringWithFormat:@"%d", [self intValue]];
    return text;
}

@end
