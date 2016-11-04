//
//  UIActivityViewController+ChatSecure.h
//  ChatSecure
//
//  Created by David Chiles on 10/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface UIActivityViewController (ChatSecure)

+ (instancetype)otr_linkActivityViewControllerWithURLs:(NSArray *)urlArray;

@end
