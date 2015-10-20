//
//  OTRColors.h
//  Off the Record
//
//  Created by David Chiles on 1/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <ChatSecureCore/ChatSecureCore-Swift.h>

@interface OTRColors : NSObject

+(UIColor *)colorWithStatus:(ThreadStatus)status;

+ (UIColor *)darkenColor:(UIColor *)color withValue:(CGFloat)value;
+ (UIColor *)bubbleBlueColor;
+ (UIColor *)bubbleLightGrayColor;

+ (UIColor *)blueInfoColor;
+ (UIColor *)redErrorColor;
+ (UIColor *)greenNoErrorColor;
+ (UIColor *)warnColor;

+ (UIColor *)defaultBlueColor;

@end
