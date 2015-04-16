//
//  OTRTouchAndHoldGestureRecognizer.m
//  ChatSecure
//
//  Created by David Chiles on 4/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRTouchAndHoldGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation OTRTouchAndHoldGestureRecognizer

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.state = UIGestureRecognizerStateBegan;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.state = UIGestureRecognizerStateCancelled;
}

@end
