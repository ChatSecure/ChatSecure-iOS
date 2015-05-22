//
//  OTRValueSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
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

#import "OTRValueSetting.h"
#import "OTRConstants.h"

@implementation OTRValueSetting
@synthesize key, defaultValue;

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
    if (!key || !settingsValue) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:settingsValue forKey:key];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRSettingsValueUpdatedNotification object:key userInfo:@{key: settingsValue}];
}





@end
