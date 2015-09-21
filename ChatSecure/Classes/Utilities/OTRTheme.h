//
//  OTRTheme.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 6/10/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OTRTheme : NSObject

@property (nonatomic, strong) UIColor *mainThemeColor;
@property (nonatomic, strong) UIColor *lightThemeColor;

@property (nonatomic, strong) UIColor *buttonLabelColor;

/** Set global app appearance via UIAppearance */
- (void) setupGlobalTheme;

@end
