//
//  DTCustomColoredAccessory.m
//  ChatSecure
//
//  Created by Diana Perez on 12/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "DTCustomColoredAccessory.h"

@implementation DTCustomColoredAccessory

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}



+ (DTCustomColoredAccessory *)accessoryWithColor:(UIColor *)color type:(DTCustomColoredAccessoryType)type
{
    DTCustomColoredAccessory *ret = [[DTCustomColoredAccessory alloc] initWithFrame:CGRectMake(0, 0, 15.0, 15.0)];
    ret.accessoryColor = color;
    ret.type = type;
    
    return ret;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    
    const CGFloat R = 4.5;
    
    switch (_type)
    {
        case DTCustomColoredAccessoryTypeRight:
        {
            // (x,y) is the tip of the arrow
            CGFloat x = CGRectGetMaxX(self.bounds)-3.0;;
            CGFloat y = CGRectGetMidY(self.bounds);
            
            CGContextMoveToPoint(ctxt, x-R, y-R);
            CGContextAddLineToPoint(ctxt, x, y);
            CGContextAddLineToPoint(ctxt, x-R, y+R);
            
            break;
        }
            
        case DTCustomColoredAccessoryTypeUp:
        {
            // (x,y) is the tip of the arrow
            CGFloat x = CGRectGetMaxX(self.bounds)-7.0;;
            CGFloat y = CGRectGetMinY(self.bounds)+5.0;
            
            CGContextMoveToPoint(ctxt, x-R, y+R);
            CGContextAddLineToPoint(ctxt, x, y);
            CGContextAddLineToPoint(ctxt, x+R, y+R);
            
            break;
        }
            
        case DTCustomColoredAccessoryTypeDown:
        {
            // (x,y) is the tip of the arrow
            CGFloat x = CGRectGetMaxX(self.bounds)-7.0;;
            CGFloat y = CGRectGetMaxY(self.bounds)-5.0;
            
            CGContextMoveToPoint(ctxt, x-R, y-R);
            CGContextAddLineToPoint(ctxt, x, y);
            CGContextAddLineToPoint(ctxt, x+R, y-R);
            
            break;
        }
            
        default:
            break;
    }
    
    CGContextSetLineCap(ctxt, kCGLineCapSquare);
    CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
    CGContextSetLineWidth(ctxt, 3);
    
    if (self.highlighted)
    {
        [self.highlightedColor setStroke];
    }
    else
    {
        [self.accessoryColor setStroke];
    }
    
    CGContextStrokePath(ctxt);
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [self setNeedsDisplay];
}

- (UIColor *)accessoryColor
{
    if (!_accessoryColor)
    {
        return [UIColor blackColor];
    }
    
    return _accessoryColor;
}

- (UIColor *)highlightedColor
{
    if (!_highlightedColor)
    {
        return [UIColor whiteColor];
    }
    
    return _highlightedColor;
}

@synthesize accessoryColor = _accessoryColor;
@synthesize highlightedColor = _highlightedColor;
@synthesize type = _type;

@end