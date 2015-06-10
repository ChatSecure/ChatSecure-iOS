//
//  OTRWelcomeViewController.h
//  ChatSecure
//
//  Created by David Chiles on 5/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRCircleView;

@interface OTRWelcomeAccountInfo : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *labelText;
@property (nonatomic, copy) void (^didSelectBlock)(void);

+ (instancetype)accountInfoWithText:(NSString *)text image:(UIImage *)image didSelectBlock:(void (^)(void))didSelectBlock;

@end

@interface OTRWelcomeViewController : UIViewController

@property (nonatomic, strong, readonly) UIImageView *brandImageView;
@property (nonatomic, strong, readonly) UILabel *createLabel;
@property (nonatomic, strong, readonly) UILabel *anonymousLabel;
@property (nonatomic, strong, readonly) OTRCircleView *createView;
@property (nonatomic, strong, readonly) OTRCircleView *anonymousView;
@property (nonatomic, strong, readonly) UIView *accountPickerHeaderView;
@property (nonatomic, strong, readonly) UILabel *accountPickkerHeaderLabel;
@property (nonatomic, strong, readonly) UIImageView *accountPickerHeaderImageView;

@property (nonatomic, strong, readonly) NSArray *accountInfoArray;

@property (nonatomic, copy) void (^successBlock)(void);

- (instancetype) initWithDefaultAccountArray;

- (NSArray *)defaultAccountArray;

@end
