//
//  OTRGlobalState.m
//  ChatSecure
//
//  Created by Chris Ballinger on 12/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRGlobalState.h"

#if TARGET_OS_IPHONE
@import UIKit;
#else
#endif

@implementation OTRGlobalState

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
