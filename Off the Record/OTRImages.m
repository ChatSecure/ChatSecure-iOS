//
//  OTRstatusImage.m
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRImages.h"



@implementation OTRImages

+(UIColor *)colorWithStatus:(OTRBuddyStatus)status
{
    switch(status)
    {
        case OTRBuddyStatusOffline:
            return [UIColor colorWithRed: 0.763 green: 0.763 blue: 0.763 alpha: 1];
            break;
        case OTRBuddyStatusAway:
            return [UIColor colorWithRed: 0.901 green: 0.527 blue: 0.23 alpha: 1];
            break;
        case OTRBuddyStatusXa:
            return [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case OTRBuddyStatusDnd:
            return [UIColor colorWithRed: 0.734 green: 0.124 blue: 0.124 alpha: 1];
            break;
        case OTRBuddyStatusAvailable:
            return [UIColor colorWithRed: 0.083 green: 0.767 blue: 0.194 alpha: 1];
            break;
        default:
            return [UIColor colorWithRed: 0.763 green: 0.763 blue: 0.763 alpha: 1];
            break;
    }
    
}

+(UIImage *)rawStatusImageWithStatus:(OTRBuddyStatus)status
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18, 18), NO, 0);
    
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* bubbleColor = [OTRImages colorWithStatus:status];
    CGFloat bubbleColorRGBA[4];
    [bubbleColor getRed: &bubbleColorRGBA[0] green: &bubbleColorRGBA[1] blue: &bubbleColorRGBA[2] alpha: &bubbleColorRGBA[3]];
    
    UIColor* strokeColor = [UIColor colorWithRed: (bubbleColorRGBA[0] * 0.5) green: (bubbleColorRGBA[1] * 0.5) blue: (bubbleColorRGBA[2] * 0.5) alpha: (bubbleColorRGBA[3] * 0.5 + 0.5)];
    UIColor* outerShaddowColor = [bubbleColor colorWithAlphaComponent: 0.6];
    
    //// Shadow Declarations
    UIColor* outerShaddow = outerShaddowColor;
    CGSize outerShaddowOffset = CGSizeMake(0.1, -0.1);
    CGFloat outerShaddowBlurRadius = 3;
    
    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(3, 3, 12, 12)];
    [bubbleColor setFill];
    [ovalPath fill];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, outerShaddowOffset, outerShaddowBlurRadius, outerShaddow.CGColor);
    [strokeColor setStroke];
    ovalPath.lineWidth = 1;
    [ovalPath stroke];
    CGContextRestoreGState(context);
    
    UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dotImage;

}

+ (UIImage *)statusImageWithStatus:(OTRBuddyStatus)status
{
    switch (status) {
        case OTRBuddyStatusDnd:
            return [OTRImages dndImage];
            break;
        case OTRBuddyStatusXa:
            return [OTRImages xaImage];
            break;
        case OTRBuddyStatusAvailable:
            return [OTRImages availableImage];
            break;
        case OTRBuddyStatusAway:
            return [OTRImages awayImage];
            break;
        default:
            return [OTRImages offlineImage];
            break;
    }
    
}

+ (UIImage*) offlineImage {
    static UIImage *offlineImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        offlineImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusOffline];
    });
    return offlineImage;
}

+ (UIImage*) awayImage {
    static UIImage *awayImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        awayImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusAway];
    });
    return awayImage;
}

+ (UIImage*) availableImage {
    static UIImage *availableImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        availableImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusAvailable];
    });
    return availableImage;
}

+ (UIImage*) xaImage {
    static UIImage *xaImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xaImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusXa];
    });
    return xaImage;
}

+ (UIImage*) dndImage {
    static UIImage *dndImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dndImage = [OTRImages rawStatusImageWithStatus:OTRBuddyStatusDnd];
    });
    return dndImage;
}

+(UIImage *)caratImage
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), NO, 0);
    //// Color Declarations
    UIColor* strokeColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    
    //// Polygon Drawing
    UIBezierPath* polygonPath = [UIBezierPath bezierPath];
    [polygonPath moveToPoint: CGPointMake(6, 10.39)];
    [polygonPath addLineToPoint: CGPointMake(0.8, 2.6)];
    [polygonPath addLineToPoint: CGPointMake(11.2, 2.6)];
    [polygonPath closePath];
    [strokeColor setFill];
    [polygonPath fill];
    
    UIImage *carat = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return carat;
    
}

+(CGFloat)scale
{
    CGFloat scale = 1.0;
    if([[UIScreen mainScreen]respondsToSelector:@selector(scale)]) {
        CGFloat tmp = [[UIScreen mainScreen]scale];
        if (tmp > 1.5) {
            scale = 2.0;
        }
    }
    
    return scale;
}

+(UIImage *)openCaratImage
{
    
    
    UIImage * carat = [OTRImages caratImage];
    return [[UIImage alloc] initWithCGImage:carat.CGImage scale:[OTRImages scale] orientation:UIImageOrientationLeft];
    return carat;
    
}
+(UIImage *)closeCaratImage
{
    UIImage * carat = [OTRImages caratImage];
    return [[UIImage alloc] initWithCGImage: carat.CGImage
                               scale: [OTRImages scale] 
                         orientation: UIImageOrientationUp];
    
}

+ (UIImage *)image:(UIImage *)image maskWithColor:(UIColor *)maskColor
{
    CGRect imageRect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, self.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(ctx, 1.0f, -1.0f);
    CGContextTranslateCTM(ctx, 0.0f, -(imageRect.size.height));
    
    CGContextClipToMask(ctx, imageRect, image.CGImage);
    CGContextSetFillColorWithColor(ctx, maskColor.CGColor);
    CGContextFillRect(ctx, imageRect);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIColor *)darkenColor:(UIColor *)color withValue:(CGFloat)value
{
    NSUInteger totalComponents = CGColorGetNumberOfComponents(color.CGColor);
    BOOL isGreyscale = (totalComponents == 2) ? YES : NO;
    
    CGFloat *oldComponents = (CGFloat *)CGColorGetComponents(color.CGColor);
    CGFloat newComponents[4];
    
    if (isGreyscale) {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[2] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[3] = oldComponents[1];
    }
    else {
        newComponents[0] = oldComponents[0] - value < 0.0f ? 0.0f : oldComponents[0] - value;
        newComponents[1] = oldComponents[1] - value < 0.0f ? 0.0f : oldComponents[1] - value;
        newComponents[2] = oldComponents[2] - value < 0.0f ? 0.0f : oldComponents[2] - value;
        newComponents[3] = oldComponents[3];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef newColor = CGColorCreate(colorSpace, newComponents);
	CGColorSpaceRelease(colorSpace);
    
	UIColor *retColor = [UIColor colorWithCGColor:newColor];
	CGColorRelease(newColor);
    
    return retColor;
}

+ (UIColor *)bubbleBlueColor
{
    return [UIColor colorWithHue:210.0f / 360.0f
                      saturation:0.94f
                      brightness:1.0f
                           alpha:1.0f];
}

+ (UIColor *)bubbleLightGrayColor
{
    return [UIColor colorWithHue:240.0f / 360.0f
                      saturation:0.02f
                      brightness:0.92f
                           alpha:1.0f];
}

+ (UIImage *)mirrorImage:(UIImage *)image {
    return [UIImage imageWithCGImage:image.CGImage
                               scale:image.scale
                         orientation:UIImageOrientationUpMirrored];
}

+ (UIImageView *)bubbleImageViewForType:(OTRBubbleMessageType)type
                                  color:(UIColor *)color
{
    UIImage *bubble = [UIImage imageNamed:@"bubble-min"];
    
    
    UIImage *normalBubble = [self image:bubble maskWithColor:color];
    UIImage *highlightedBubble = [self image:bubble maskWithColor:[self darkenColor:color withValue:0.12f]];
    
    if (type == OTRBubbleMessageTypeIncoming) {
        normalBubble = [self mirrorImage:normalBubble];
        highlightedBubble = [self mirrorImage:normalBubble];
    }
    
    // make image stretchable from center point
    CGPoint center = CGPointMake(bubble.size.width / 2.0f, bubble.size.height / 2.0f);
    UIEdgeInsets capInsets = UIEdgeInsetsMake(center.y, center.x, center.y, center.x);
    
    normalBubble = [normalBubble resizableImageWithCapInsets:capInsets
                                                resizingMode:UIImageResizingModeStretch];
    highlightedBubble = [highlightedBubble resizableImageWithCapInsets:capInsets
                                                          resizingMode:UIImageResizingModeStretch];
    
    return [[UIImageView alloc] initWithImage:normalBubble
                             highlightedImage:highlightedBubble];
}

+ (UIImageView *)classicBubbleImageViewForType:(OTRBubbleMessageType)type
{
    UIImage * bubbleImage;
    UIImage * highlightedBubble = [UIImage imageNamed:@"MessageBubbleBlue"];
    if (type == OTRBubbleMessageTypeIncoming) {
        bubbleImage = [UIImage imageNamed:@"MessageBubbleGrey"];
        highlightedBubble = [self mirrorImage:highlightedBubble];
    }
    else if (type == OTRBubbleMessageTypeOutgoing) {
        bubbleImage = [UIImage imageNamed:@"MessageBubbleBlue"];
    }
    UIEdgeInsets insets = UIEdgeInsetsMake(15.0f, 20.0f, 15.0f, 20.0f);
    bubbleImage = [bubbleImage resizableImageWithCapInsets:insets
                                              resizingMode:UIImageResizingModeStretch];
    highlightedBubble = [highlightedBubble resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
    
    return [[UIImageView alloc] initWithImage:bubbleImage
                             highlightedImage:highlightedBubble];
    
}

+(UIImageView *)bubbleImageViewForMessageType:(OTRBubbleMessageType)bubbleMessageType
{
    UIImageView * bubbleImageView = nil;
    if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
        UIColor * color = nil;
        if (bubbleMessageType == OTRBubbleMessageTypeIncoming ) {
            color = [self bubbleLightGrayColor];
        }
        else {
            color = [self bubbleBlueColor];
        }
        bubbleImageView = [self bubbleImageViewForType:bubbleMessageType color:color];
    }
    else {
        bubbleImageView = [self classicBubbleImageViewForType:bubbleMessageType];
    }
    return bubbleImageView;
}

+(UIImageView *)typingBubbleImageView
{
    UIImageView * bubbleImageView = nil;
    UIImage * bubbleImage = nil;
    if (SYSTEM_VERSION_GREATER_THAN(@"7.0")) {
        
    }
    else {
        bubbleImage = [UIImage imageNamed:@"MessageBubbleTyping"];
    }
    return bubbleImageView;

}


@end
