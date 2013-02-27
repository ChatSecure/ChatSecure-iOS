//
//  OTRIntSetting.h
//  Off the Record
//
//  Created by David on 2/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDoubleSetting.h"

@interface OTRIntSetting : OTRValueSetting

@property (nonatomic) NSInteger intValue;
@property (nonatomic) NSInteger minValue;
@property (nonatomic) NSInteger maxValue;
@property (nonatomic) NSInteger numValues;
@property (nonatomic, retain) NSNumber *defaultValue;


- (void) editValue;
- (NSString*) stringValue;

@end
