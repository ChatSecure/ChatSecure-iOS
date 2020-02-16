//
//  OTREncryptionDropdown.h
//  Off the Record
//
//  Created by David Chiles on 2/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN
@interface OTRButtonView : UIView

@property (nonnull, strong) NSLayoutConstraint *topLayoutConstraint;

- (id)initWithTitle:(NSString *)title buttons:(NSArray *)buttons;

+ (CGFloat )heightForTitle:(NSString *)title width:(CGFloat)width buttons:(NSArray *)buttons;

@end
NS_ASSUME_NONNULL_END
