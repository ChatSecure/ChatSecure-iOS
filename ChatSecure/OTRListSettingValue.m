//
//  OTRListSettingValue.m
//  ChatSecure
//
//  Created by David Chiles on 11/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRListSettingValue.h"

@implementation OTRListSettingValue

- (instancetype)initWithTitle:(NSString *)title detail:(NSString *)detail value:(id)value
{
    if (self = [self init]) {
        _title = title;
        _detail = detail;
        _value = value;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@) - %@",self.title,self.detail,self.value];
}

@end
