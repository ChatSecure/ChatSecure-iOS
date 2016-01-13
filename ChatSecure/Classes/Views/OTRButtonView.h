//
//  OTREncryptionDropdown.h
//  Off the Record
//
//  Created by David Chiles on 2/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@import OTRKit;

@interface OTRButtonView : UIView

- (id)initWithTitle:(NSString *)title buttons:(NSArray *)buttons;


+ (CGFloat )heightForTitle:(NSString *)title width:(CGFloat)width buttons:(NSArray *)buttons;

@end
