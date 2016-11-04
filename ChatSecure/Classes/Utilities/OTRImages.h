//
//  OTRstatusImage.h
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import Foundation;
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

+ (UIImage *)duckduckgoImage;

+ (UIImage *)xmppServerImageWithName:(NSString *)name;

+ (UIImage *)warningImage;
+ (UIImage *)circleWarningWithColor:(UIColor *)color;
+ (UIImage *)warningImageWithColor:(UIColor *)color;

+ (UIImage *)checkmarkWithColor:(UIColor *)color;

+ (UIImage *)errorWithColor:(UIColor *)color;

+ (UIImage *)wifiWithColor:(UIColor *)color;

+ (UIImage *)microphoneWithColor:(UIColor *)color size:(CGSize)size;

+ (UIImage *)imageWithIdentifier:(NSString *)identifier;
+ (void)removeImageWithIdentifier:(NSString *)identifier;
+ (void)setImage:(UIImage *)image forIdentifier:(NSString *)identifier;

+ (UIImage *)avatarImageWithUsername:(NSString *)username;

/**
 This creates and caches either the image from the avatarData or the initials image created from dispalyName or username. If a cached image is available then that will be returned.
 
 @param identifier Required if the image is to be cached
 @param avatarData Optional primary source of the UIimage
 @param displayName Optional the secondary source for generating an avatar
 @param username Optional the last source for generating an avatar
 @return An UIImage that represents the best possible image
 */
+ (UIImage *)avatarImageWithUniqueIdentifier:(NSString *)identifier avatarData:(NSData *)data displayName:(NSString *)displayName username:(NSString *)username;


@end
