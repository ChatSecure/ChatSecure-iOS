//
//  OTRSettingsGroup.h
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


@import Foundation;

@class OTRSetting;

NS_ASSUME_NONNULL_BEGIN
@interface OTRSettingsGroup : NSObject

@property (nonatomic, readonly) NSArray<OTRSetting*> *settings;
@property (nonatomic, readonly) NSString *title;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype) initWithTitle:(NSString*)title;
- (instancetype) initWithTitle:(NSString*)title settings:(nullable NSArray<OTRSetting*>*)settings NS_DESIGNATED_INITIALIZER;

- (void) addSetting:(OTRSetting*)setting;

@end
NS_ASSUME_NONNULL_END
