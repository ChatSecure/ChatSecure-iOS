//
//  UIActivityViewController+ChatSecure.m
//  ChatSecure
//
//  Created by David Chiles on 10/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "UIActivityViewController+ChatSecure.h"
@import ARChromeActivity;
#import "OTROpenInFacebookActivity.h"
#import "OTROpenInTwitterActivity.h"
@import OTRAssets;
#import "UIActivity+ChatSecure.h"


@implementation UIActivityViewController (ChatSecure)

+ (instancetype)otr_linkActivityViewControllerWithURLs:(NSArray *)urlArray
{
    if (!urlArray.count) {
        return nil;
    }
    return [[self alloc] initWithActivityItems:urlArray applicationActivities:UIActivity.otr_linkActivities];
}



@end
