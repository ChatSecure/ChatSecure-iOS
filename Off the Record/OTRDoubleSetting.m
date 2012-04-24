//
//  OTRDoubleSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRDoubleSetting.h"

@implementation OTRDoubleSetting
@synthesize doubleValue;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        self.action = @selector(editValue);
    }
    return self;
}

- (void) editValue {
    
}

- (void) setDoubleValue:(double)value {
    [self setValue:[NSNumber numberWithDouble:value]];
    [self.delegate refreshView];
}

- (double) doubleValue {
    return [[self value] doubleValue];
}

@end
