//
//  UIViewController+chatsecure.m
//  ChatSecure
//
//  Created by David Chiles on 9/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "UIViewController+ChatSecure.h"

@implementation UIViewController (ChatSecure)

- (BOOL)otr_isVisible
{
    return (self.isViewLoaded && self.view.window);
}

@end
