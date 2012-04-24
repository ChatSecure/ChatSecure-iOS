//
//  OTRBoolSetting.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRValueSetting.h"

@interface OTRBoolSetting : OTRValueSetting

@property (nonatomic) BOOL enabled;

- (void) toggle;

@end
