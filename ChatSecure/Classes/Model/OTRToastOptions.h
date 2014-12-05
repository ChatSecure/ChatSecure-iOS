//
//  OTRToastOptions.h
//  ChatSecure
//
//  Created by David Chiles on 12/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "CRToast.h"

typedef NS_ENUM(NSUInteger, OTRToastOptionType) {
    OTRToastOptionTypeDefault,
    OTRToastOptionTypeSuccess,
    OTRToastOptionTypeWarn,
    OTRToastOptionTypeFailure
};

extern CGSize const kOTRDefaultNotificationImageSize;

@interface OTRToastOptions : NSObject

@property (nonatomic) CRToastType toastType;
@property (nonatomic) CRToastPresentationType presentationType;
@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) CRToastAnimationDirection animationInDirection;
@property (nonatomic) CRToastAnimationDirection animationOutDirection;

@property (nonatomic) CRToastAnimationType animationInType;
@property (nonatomic) CRToastAnimationType animationOutType;

//Array of CRToastInteractionResponder
@property (nonatomic, strong) NSArray *interactionResponders;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *subtitleText;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIImage *image;

- (instancetype)initWithText:(NSString *)text subtitleText:(NSString *)subtitleText;
- (instancetype)initWithText:(NSString *)text subtitleText:(NSString *)subtitleText optionType:(OTRToastOptionType)option;

- (void)addInteractionResponderWithType:(CRToastInteractionType)type
                   automaticallyDismiss:(BOOL)automaticallyDismiss
                                  block:(void (^)(CRToastInteractionType interactionType))block;

- (NSDictionary *)dictionary;

+ (instancetype)optionsWithText:(NSString *)text subtitleText:(NSString *)subtitleText;
+ (instancetype)optionsWithText:(NSString *)text subtitleText:(NSString *)subtitleText optionType:(OTRToastOptionType)option;

@end