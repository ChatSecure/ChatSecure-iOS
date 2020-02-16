//
//  OTRColors.h
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

#import "OTRThreadOwner.h"

NS_ASSUME_NONNULL_BEGIN
@interface OTRColors : NSObject

+(UIColor *)colorWithStatus:(OTRThreadStatus)status;

+ (UIColor *)darkenColor:(UIColor *)color withValue:(CGFloat)value;
+ (UIColor *)bubbleBlueColor;
+ (UIColor *)bubbleLightGrayColor;

+ (UIColor *)blueInfoColor;
+ (UIColor *)redErrorColor;
+ (UIColor *)greenNoErrorColor;
+ (UIColor *)warnColor;

+ (UIColor *)defaultBlueColor;
@end
NS_ASSUME_NONNULL_END
