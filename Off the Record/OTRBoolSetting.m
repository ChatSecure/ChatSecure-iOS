//
//  OTRBoolSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRBoolSetting.h"

@implementation OTRBoolSetting
@synthesize boolSwitch, action;

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        self.action = @selector(toggle);
        self.boolSwitch = [[UISwitch alloc] init];
        [boolSwitch addTarget:self action:self.action forControlEvents:UIControlEventValueChanged];
        boolSwitch.on = [self enabled];

    }
    return self;
}

- (void) toggle 
{
    [self setEnabled:![self enabled]];
}

- (void) setEnabled:(BOOL)enabled
{
    [self setValue:[NSNumber numberWithBool:enabled]];
    [boolSwitch setOn:enabled animated:YES];
}

- (BOOL) enabled
{
    return [[self value] boolValue];
}

@end
