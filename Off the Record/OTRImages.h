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

+ (UIImage *)statusImageWithStatus:(OTRBuddyStatus)status;

+ (UIImage *)openCaratImage;
+ (UIImage *)closeCaratImage;


+ (UIImageView *)bubbleImageViewForMessageType:(OTRBubbleMessageType)bubbleMessageType;
+ (UIView *)typingBubbleView;

+ (UIImage *)circleWithRadius:(CGFloat)radius;

+ (UIImage *)facebookImage;


+(UIColor *)colorWithStatus:(OTRBuddyStatus)status;

@end
