//
//  OTRViewSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRViewSetting.h"
@import UIKit;

@implementation OTRViewSetting
@synthesize viewControllerClass, delegate;

- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription viewControllerClass:(Class)newViewControllerClass;
{
    if (self = [super initWithTitle:newTitle description:newDescription])
    {
        viewControllerClass = newViewControllerClass;
        __weak typeof (self) weakSelf = self;
        self.actionBlock = ^void(id sender){
            [weakSelf showView];
        };
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    return self;
}

- (void) showView
{
    [self.delegate otrSetting:self showDetailViewControllerClass:viewControllerClass];
}


@end
