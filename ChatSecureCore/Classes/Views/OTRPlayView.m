//
//  OTRPlayView.m
//  ChatSecure
//
//  Created by David Chiles on 1/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRPlayView.h"

@implementation OTRPlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.angle = M_PI/3;
        self.color = [UIColor blackColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawPlayTriangleInRect:(CGRect)rect
{
    /**
     We don't want to center the triangle based on it's height. Think of it as a circle centered in the rect and then inscribe a equilateral triangle inside of it
     http://stackoverflow.com/questions/11449856/draw-a-equilateral-triangle-given-the-center
     */
    
    CGFloat rectHeight = CGRectGetHeight(rect);
    CGFloat rectWidth = CGRectGetHeight(rect);
    
    CGPoint firstPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
    if (rectHeight > rectWidth) {
        firstPoint.x = firstPoint.x + CGRectGetMaxX(rect);
    } else {
        firstPoint.x = firstPoint.x + rectWidth - ((rectWidth - rectHeight) / 2);
    }
    
    //Angle for equalateral triangles are 60 degrees or pi/3
    //This is the angle of the right most 'pointy' side of play icon
    
    //length = 2 * radius * cos(angle/2)
    CGFloat triangleEdgeLength = MIN(rectHeight, rectWidth) * cosf(self.angle/2);
    
    CGFloat xDif = cos(self.angle/2)*triangleEdgeLength;
    CGFloat yDif = sin(self.angle/2)*triangleEdgeLength;
    
    CGPoint secondPoint = CGPointMake(firstPoint.x - xDif, firstPoint.y - yDif);
    CGPoint thirdPoint = CGPointMake(secondPoint.x, firstPoint.y + yDif);
    
    UIBezierPath* trianglePath = UIBezierPath.bezierPath;
    [trianglePath moveToPoint:firstPoint];
    [trianglePath addLineToPoint:secondPoint];
    [trianglePath addLineToPoint:thirdPoint];
    [trianglePath moveToPoint:firstPoint];
    [trianglePath closePath];
    [self.color setFill];
    [trianglePath fill];
}

- (void)drawRect:(CGRect)rect
{
    [self drawPlayTriangleInRect:rect];
}

@end
