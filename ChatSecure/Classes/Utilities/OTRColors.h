//
//  OTRColors.h
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OTRBuddy.h"

@interface OTRColors : NSObject

+(UIColor *)colorWithStatus:(OTRBuddyStatus)status;

+ (UIColor *)darkenColor:(UIColor *)color withValue:(CGFloat)value;
+ (UIColor *)bubbleBlueColor;
+ (UIColor *)bubbleLightGrayColor;

+ (UIColor *)redErrorColor;
+ (UIColor *)greenNoErrorColor;
+ (UIColor *)warnColor;

@end
