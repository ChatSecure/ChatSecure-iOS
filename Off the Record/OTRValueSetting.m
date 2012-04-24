//
//  OTRValueSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRValueSetting.h"

@implementation OTRValueSetting
@synthesize key;

- (void) dealloc
{
    key = nil;
}

- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription settingsKey:(NSString*)newSettingsKey;
{
    if (self = [super initWithTitle:newTitle description:newDescription])
    {
        key = newSettingsKey;
    }
    return self;
}

- (id) value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

- (void) setValue:(id)settingsValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:settingsValue forKey:key];
    [defaults synchronize];
}





@end
