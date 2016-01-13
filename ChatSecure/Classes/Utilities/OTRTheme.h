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

/** Override this in subclass to use a different conversation view controller class */
- (Class) conversationViewControllerClass;

/** Override this in subclass to use a different message view controller class */
- (Class) messagesViewControllerClass;

/** Override this in subclass to use a different group message view controller class */
- (Class) groupMessagesViewControllerClass;

/** Override this in subclass to use a different compose view controller class */
- (Class) composeViewControllerClass;



@end
