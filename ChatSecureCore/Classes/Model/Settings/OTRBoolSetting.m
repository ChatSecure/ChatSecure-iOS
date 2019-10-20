//
//  OTRBoolSetting.m
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

#import "OTRBoolSetting.h"

@implementation OTRBoolSetting

- (id) initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        __weak typeof (self) weakSelf = self;
        self.actionBlock = ^void(id sender) {
            [weakSelf toggle];
        };
        self.defaultValue = [NSNumber numberWithBool:NO];
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
    [self.delegate refreshView];
}

- (BOOL) enabled
{
    if (![self value]) 
    {
        self.value = self.defaultValue;
    }
    return [[self value] boolValue];
}

@end
