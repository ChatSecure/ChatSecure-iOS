//
//  OTROpenInTwitterActivity.m
//  ChatSecure
//
//  Created by David Chiles on 10/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTROpenInTwitterActivity.h"
#import "OTRImages.h"
#import "UIImage+ChatSecure.h"
#import "UIActivity+ChatSecure.h"
#import "ChatSecureCoreCompat-Swift.h"
@import OTRAssets;


@interface OTROpenInTwitterActivity ()

@property (nonatomic, strong) NSURL *url;

@end

@implementation OTROpenInTwitterActivity

- (NSURL *)urlFromActivities:(NSArray *)activityItems
{
    __block NSURL *finalURL = nil;
    [activityItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSURL class] ]) {
            NSURL *url = (NSURL *)obj;
            if ([[url scheme] isEqualToString:@"twitter"]) {
                finalURL = url;
                *stop = YES;
            }
        }
    }];
    return finalURL;
}

#pragma - mark Override

- (NSString *)activityTitle
{
    return OPEN_IN_TWITTER_STRING();
}

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (UIImage *)activityImage
{
    return [UIImage otr_imageWithImage:[OTRImages twitterImage] scaledToSize:[UIActivity otr_defaultImageSize]];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        return NO;
    }
    
    if ([self urlFromActivities:activityItems]) {
        return YES;
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    self.url = [self urlFromActivities:activityItems];
}

- (void)performActivity
{
    [[UIApplication sharedApplication] open:self.url];
    [self activityDidFinish:YES];
}

@end
