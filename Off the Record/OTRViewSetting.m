//
//  OTRViewSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRViewSetting.h"

@implementation OTRViewSetting
@synthesize viewControllerClass, delegate;

- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription viewControllerClass:(Class)newViewControllerClass;
{
    if (self = [super initWithTitle:newTitle description:newDescription])
    {
        viewControllerClass = newViewControllerClass;
        self.action = @selector(showView);
    }
    return self;
}

- (void) showView
{
    [self.delegate showViewControllerClass:viewControllerClass];
}


@end
