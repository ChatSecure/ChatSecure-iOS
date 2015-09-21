//
//  OTRAssets.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 9/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAssets.h"

@implementation OTRAssets

/** Returns OTRResources.bundle */
+ (NSBundle*) resourcesBundle {
    NSString *folderName = @"OTRResources.bundle";
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName];
    NSBundle *dataBundle = [NSBundle bundleWithPath:bundlePath];
    NSParameterAssert(dataBundle != nil);
    return dataBundle;
}

@end