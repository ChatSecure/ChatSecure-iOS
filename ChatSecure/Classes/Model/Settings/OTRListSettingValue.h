//
//  OTRListSettingValue.h
//  ChatSecure
//
//  Created by David Chiles on 11/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

@interface OTRListSettingValue : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *detail;
@property (nonatomic, strong, readonly) id value;

- (instancetype)initWithTitle:(NSString *)title detail:(NSString *)detail value:(id)value;

@end
