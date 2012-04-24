//
//  OTRDoubleSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRDoubleSetting.h"

@implementation OTRDoubleSetting
@synthesize doubleValue;

- (void) setDoubleValue:(double)value {
    [self setValue:[NSNumber numberWithDouble:value]];
    
}

@end
