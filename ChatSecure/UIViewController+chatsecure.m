//
//  UIViewController+chatsecure.m
//  ChatSecure
//
//  Created by David Chiles on 9/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "UIViewController+chatsecure.h"

@implementation UIViewController (chatsecure)

- (BOOL)isVisible
{
    return (self.isViewLoaded && self.view.window);
}

@end
