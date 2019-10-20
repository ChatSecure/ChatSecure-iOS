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
@synthesize delegate = _delegate;
@synthesize defaultValue = _defaultValue;
@synthesize intValue, minValue, maxValue, numValues;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        __weak typeof (self) weakSelf = self;
        self.actionBlock = ^void(id sender){
            [weakSelf editValue];
        };
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
    [self setValue:[NSNumber numberWithInt:(int)value]];
    if(self.delegate && [self.delegate conformsToProtocol:@protocol(OTRSettingDelegate)]) {
        [self.delegate refreshView];
    }
}

- (NSInteger) intValue {
    if (![self value])
    {
        self.value = self.defaultValue;
    }
    return [(NSNumber*)[self value] intValue];
}

- (NSString*) stringValue {
    NSString *text = [NSString stringWithFormat:@"%d", (int)[self intValue]];
    return text;
}

@end
