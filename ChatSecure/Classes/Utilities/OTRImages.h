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

#if TARGET_OS_IPHONE
#define OTRImage UIImage
#else
#define OTRImage NSImage
#endif

@interface OTRImages : NSObject


+ (OTRImage *)circleWithRadius:(CGFloat)radius;
+ (OTRImage *)circleWithRadius:(CGFloat)radius lineWidth:(CGFloat)lineWidth lineColor:(UIColor *)lineColor fillColor:(UIColor *)fillColor;

+ (OTRImage *)twitterImage;

+ (OTRImage *)facebookActivityImage;

+ (OTRImage *)duckduckgoImage;

+ (OTRImage *)xmppServerImageWithName:(NSString *)name;

+ (OTRImage *)warningImage;
+ (OTRImage *)circleWarningWithColor:(UIColor *)color;
+ (OTRImage *)warningImageWithColor:(UIColor *)color;

+ (OTRImage *)checkmarkWithColor:(UIColor *)color;

+ (OTRImage *)errorWithColor:(UIColor *)color;

+ (OTRImage *)wifiWithColor:(UIColor *)color;

+ (OTRImage *)microphoneWithColor:(UIColor *)color size:(CGSize)size;

+ (OTRImage *)imageWithIdentifier:(NSString *)identifier;
+ (void)removeImageWithIdentifier:(NSString *)identifier;
+ (void)setImage:(OTRImage *)image forIdentifier:(NSString *)identifier;

+ (OTRImage *)avatarImageWithUsername:(NSString *)username;

/**
 This creates and caches either the image from the avatarData or the initials image created from dispalyName or username. If a cached image is available then that will be returned.
 
 @param identifier Required if the image is to be cached
 @param avatarData Optional primary source of the UIimage
 @param displayName Optional the secondary source for generating an avatar
 @param username Optional the last source for generating an avatar
 @return An UIImage that represents the best possible image
 */
+ (OTRImage *)avatarImageWithUniqueIdentifier:(NSString *)identifier avatarData:(NSData *)data displayName:(NSString *)displayName username:(NSString *)username;


@end
