//
//  OTRDoubleSetting.m
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

#import "OTRDoubleSetting.h"
#import "OTRDoubleSettingViewController.h"

@implementation OTRDoubleSetting
@synthesize doubleValue, minValue, maxValue, numValues, isPercentage;
@synthesize delegate = _delegate;
@synthesize defaultValue = _defaultValue;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        __weak typeof (self) weakSelf = self;
        self.actionBlock = ^void(id sender){
            [weakSelf editValue];
        };
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
