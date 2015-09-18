//
//  OTRTheme.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRTheme.h"

@implementation OTRTheme

- (instancetype) init {
    if (self = [super init]) {
        _lightThemeColor = [UIColor whiteColor];
        _mainThemeColor = [UIColor blackColor];
        _buttonLabelColor = [UIColor darkGrayColor];
    }
    return self;
}

/** Set global app appearance via UIAppearance */
- (void) setupGlobalTheme {
}

@end
