//
//  OTRstatusImage.h
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRConstants.h"

@class OTRComposingImageView;

typedef NS_ENUM(NSUInteger, OTRBubbleMessageType) {
    OTRBubbleMessageTypeIncoming,
    OTRBubbleMessageTypeOutgoing
};

@interface OTRImages : NSObject

+ (UIView *)typingBubbleView;

+ (UIImage *)circleWithRadius:(CGFloat)radius;
+ (UIImage *)circleWithRadius:(CGFloat)radius lineWidth:(CGFloat)lineWidth lineColor:(UIColor *)lineColor fillColor:(UIColor *)fillColor;

+ (UIImage *)twitterImage;

+ (UIImage *)facebookActivityImage;

+ (UIImage *)facebookImage;

+ (UIImage *)warningImage;

+ (UIImage *)warningImageWithColor:(UIColor *)color;

+ (UIImage *)checkmarkWithColor:(UIColor *)color;

+ (UIImage *)errorWithColor:(UIColor *)color;

+ (UIImage *)wifiWithColor:(UIColor *)color;

+ (UIImage *)imageWithIdentifier:(NSString *)identifier;
+ (void)removeImageWithIdentifier:(NSString *)identifier;
+ (void)setImage:(UIImage *)image forIdentifier:(NSString *)identifier;

+ (UIImage *)avatarImageWithUsername:(NSString *)username;


@end
