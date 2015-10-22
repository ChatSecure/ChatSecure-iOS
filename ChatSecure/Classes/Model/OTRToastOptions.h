//
//  OTRToastOptions.h
//  ChatSecure
//
//  Created by David Chiles on 12/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import UIKit;

typedef NS_ENUM(NSUInteger, OTRToastOptionType) {
    OTRToastOptionTypeDefault,
    OTRToastOptionTypeSuccess,
    OTRToastOptionTypeWarn,
    OTRToastOptionTypeFailure
};

extern CGSize const kOTRDefaultNotificationImageSize;

/** This is deprecated! Do not use. */
@interface OTRToastOptions : NSObject

@property (nonatomic) int toastType;
@property (nonatomic) int presentationType;
@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) int animationInDirection;
@property (nonatomic) int animationOutDirection;

@property (nonatomic) int animationInType;
@property (nonatomic) int animationOutType;

//Array of CRToastInteractionResponder
@property (nonatomic, strong) NSArray *interactionResponders;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *subtitleText;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIImage *image;

- (instancetype)initWithText:(NSString *)text subtitleText:(NSString *)subtitleText;
- (instancetype)initWithText:(NSString *)text subtitleText:(NSString *)subtitleText optionType:(OTRToastOptionType)option;

- (void)addInteractionResponderWithType:(int)type
                   automaticallyDismiss:(BOOL)automaticallyDismiss
                                  block:(void (^)(int interactionType))block;

- (NSDictionary *)dictionary;

+ (instancetype)optionsWithText:(NSString *)text subtitleText:(NSString *)subtitleText;
+ (instancetype)optionsWithText:(NSString *)text subtitleText:(NSString *)subtitleText optionType:(OTRToastOptionType)option;

@end