//
//  OTRColors.h
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <ChatSecureCore/OTRThreadOwner.h>

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
