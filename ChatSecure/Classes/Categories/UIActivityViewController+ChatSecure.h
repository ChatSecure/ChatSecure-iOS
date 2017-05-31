//
//  UIActivityViewController+ChatSecure.h
//  ChatSecure
//
//  Created by David Chiles on 10/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN
@interface UIActivityViewController (ChatSecure)

+ (nullable instancetype)otr_linkActivityViewControllerWithURLs:(NSArray<NSURL*> *)urlArray;

@end
NS_ASSUME_NONNULL_END
