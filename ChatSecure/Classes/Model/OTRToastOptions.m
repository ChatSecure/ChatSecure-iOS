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
        self.toastType = 0;
        self.presentationType = 0;
        self.duration = 3;
        self.backgroundColor = [OTRColors blueInfoColor];
        self.animationInDirection = 0;
        self.animationOutDirection = 0;
        self.animationInType = 0;
        self.animationOutType = 0;
        
        [self addInteractionResponderWithType:0 automaticallyDismiss:YES block:nil];
        [self addInteractionResponderWithType:0 automaticallyDismiss:YES block:nil];
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
                self.image = [UIImage otr_imageWithImage:[OTRImages checkmarkWithColor:[UIColor whiteColor]] scaledToSize:kOTRDefaultNotificationImageSize];
                self.backgroundColor = [OTRColors greenNoErrorColor];
                break;
            case OTRToastOptionTypeWarn:
                self.image = [UIImage otr_imageWithImage:[OTRImages warningImageWithColor:[UIColor whiteColor]] scaledToSize:kOTRDefaultNotificationImageSize];
                self.backgroundColor = [OTRColors warnColor];
                break;
            case OTRToastOptionTypeFailure:
                self.image = [UIImage otr_imageWithImage:[OTRImages errorWithColor:[UIColor whiteColor]] scaledToSize:kOTRDefaultNotificationImageSize];
                self.backgroundColor = [OTRColors redErrorColor];
                break;
            default:
                break;
        }
    }
    return self;
}

- (void)addInteractionResponderWithType:(int)type
                   automaticallyDismiss:(BOOL)automaticallyDismiss
                                  block:(void (^)(int interactionType))block
{
    /*
    CRToastInteractionResponder *interactionResponder = [CRToastInteractionResponder interactionResponderWithInteractionType:type automaticallyDismiss:automaticallyDismiss block:block];
    
    if (!self.interactionResponders) {
        self.interactionResponders = @[interactionResponder];
    } else {
        self.interactionResponders = [self.interactionResponders arrayByAddingObject:interactionResponder];
    }
     */
}


- (NSDictionary *)dictionary
{
    /*
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
    
    if ([self.interactionResponders count]) {
        options[kCRToastInteractionRespondersKey] = self.interactionResponders;
    }
    
    return options;
     */
    return nil;
}

#pragma - mark Class Methods

+ (instancetype)optionsWithText:(NSString *)text subtitleText:(NSString *)subtitleText optionType:(OTRToastOptionType)option
{
    return [[self alloc] initWithText:text subtitleText:subtitleText optionType:option];
}

+ (instancetype)optionsWithText:(NSString *)text subtitleText:(NSString *)subtitleText
{
    return [self optionsWithText:text subtitleText:subtitleText optionType:OTRToastOptionTypeDefault];
}

@end
