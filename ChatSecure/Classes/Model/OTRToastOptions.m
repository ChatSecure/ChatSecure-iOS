//
//  OTRToastOptions.m
//  ChatSecure
//
//  Created by David Chiles on 12/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRToastOptions.h"
#import "OTRColors.h"
#import "OTRImages.h"
#import "UIImage+ChatSecure.h"

CGSize const kOTRDefaultNotificationImageSize = {25, 25};

@implementation OTRToastOptions

- (instancetype)init
{
    if (self = [super init]) {
        self.toastType = CRToastTypeNavigationBar;
        self.presentationType = CRToastPresentationTypeCover;
        self.duration = 3;
        self.backgroundColor = [UIColor lightGrayColor];
        self.animationInDirection = CRToastAnimationDirectionTop;
        self.animationOutDirection = CRToastAnimationDirectionTop;
        self.animationInType = CRToastAnimationTypeGravity;
        self.animationOutType = CRToastAnimationTypeGravity;
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text subtitleText:(NSString *)subtitleText
{
    return [self initWithText:text subtitleText:subtitleText optionType:OTRToastOptionTypeDefault];
}

- (instancetype)initWithText:(NSString *)text subtitleText:(NSString *)subtitleText optionType:(OTRToastOptionType)option
{
    if (self = [self init]) {
        self.text = text;
        self.subtitleText = subtitleText;
        
        switch (option) {
            case OTRToastOptionTypeSuccess:
                self.image = [UIImage otr_imageWithImage:[OTRImages checkMarkWithColor:[UIColor whiteColor]] scaledToSize:kOTRDefaultNotificationImageSize];
                self.backgroundColor = [OTRColors greenNoErrorColor];
                break;
            case OTRToastOptionTypeWarn:
                self.backgroundColor = [OTRColors warnColor];
                break;
            case OTRToastOptionTypeFailure:
                self.backgroundColor = [OTRColors redErrorColor];
                break;
            default:
                break;
        }
    }
    return self;
}




- (NSDictionary *)dictionary
{
    NSMutableDictionary *options = [@{kCRToastNotificationTypeKey : @(self.toastType),
                                      kCRToastNotificationPresentationTypeKey : @(self.presentationType),
                                      kCRToastTimeIntervalKey : @(self.duration),
                                      kCRToastBackgroundColorKey: self.backgroundColor,
                                      kCRToastAnimationInTypeKey: @(self.animationInType),
                                      kCRToastAnimationOutTypeKey: @(self.animationOutType),
                                      kCRToastAnimationInDirectionKey: @(self.animationInDirection),
                                      kCRToastAnimationOutDirectionKey: @(self.animationOutDirection)} mutableCopy];
    
    if ([self.text length]) {
        options[kCRToastTextKey] = self.text;
    }
    
    if ([self.subtitleText length]) {
        options[kCRToastSubtitleTextKey] = self.subtitleText;
    }
    
    if (self.image) {
        options[kCRToastImageKey] = self.image;
    }
    
    return options;
}

#pragma - mark Class Methods

+ (instancetype)optionsWithText:(NSString *)text subtitleText:(NSString *)subtitleText
{
    return [[self alloc] initWithText:text subtitleText:subtitleText];
}

@end
