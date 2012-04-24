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

- (void) editValue;

@end
