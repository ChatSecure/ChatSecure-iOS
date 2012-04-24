//
//  OTRDoubleSetting.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRValueSetting.h"


@interface OTRDoubleSetting : OTRValueSetting

@property (nonatomic) double doubleValue;
@property (nonatomic) double minValue;
@property (nonatomic) double maxValue;
@property (nonatomic) double defaultValue;
@property (nonatomic) BOOL isPercentage;
@property (nonatomic) NSUInteger numValues;

- (void) editValue;
- (NSString*) stringValue;

@end
