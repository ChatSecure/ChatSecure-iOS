//
//  OTRSettingsGroup.m
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

#import "OTRSettingsGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTRSettingsGroup()
@property (nonatomic, readwrite) NSMutableArray<OTRSetting*> *mutableSettings;
@end

@implementation OTRSettingsGroup

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    abort();
}

- (instancetype) initWithTitle:(NSString*)title {
    return [self initWithTitle:title settings:nil];
}

- (instancetype) initWithTitle:(NSString*)title settings:(nullable NSArray<OTRSetting*>*)settings
{
    NSParameterAssert(title);
    if (self = [super init])
    {
        _title = [title copy];
        if (settings) {
            _mutableSettings = [settings mutableCopy];
        } else {
            _mutableSettings = [NSMutableArray array];
        }
    }
    return self;
}

- (NSArray<OTRSetting*>*) settings {
    return [self.mutableSettings copy];
}

- (void) addSetting:(OTRSetting*)setting {
    NSParameterAssert(setting);
    [self.mutableSettings addObject:setting];
}

@end

NS_ASSUME_NONNULL_END
