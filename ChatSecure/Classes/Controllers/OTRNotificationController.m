//
//  OTRNotificationController.m
//  ChatSecure
//
//  Created by David Chiles on 12/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRNotificationController.h"
#import "CRToast.h"
#import "OTRConstants.h"
#import "OTRSettingsViewController.h"
#import "OTRXMPPManager.h"
#import "OTRToastOptions.h"
#import "OTRImages.h"
#import "UIImage+ChatSecure.h"
#import "OTRBaseLoginViewController.h"
#import "Strings.h"

@interface OTRNotificationController ()

@property (nonatomic, strong) NSOperationQueue *notificationQueue;
@property (nonatomic, strong) NSMutableDictionary *notificationObservers;

@property (nonatomic) BOOL started;

@end

@implementation OTRNotificationController


- (instancetype)init
{
    if (self = [super init]) {
        self.enabled = NO;
        self.notificationQueue = [NSOperationQueue mainQueue];
        self.notificationObservers = [[NSMutableDictionary alloc] init];
        self.started = NO;
        
    }
    return self;
}

- (void)start
{
    if (!self.started) {
        __weak typeof(self)weakSelf = self;
        [self addObserverWithName:kOTRProtocolLoginSuccess withBlock:^(NSNotification *note) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf showLoginSuccessNotification:note];
        }];
        
        [self addObserverWithName:kOTRProtocolLoginFail withBlock:^(NSNotification *note) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf showLoginFailureNotification:note];
        }];
        self.started = YES;
    }

}

- (void)stop
{
    if (self.started) {
        NSDictionary *observers =  [self.notificationObservers copy];
        [observers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [[NSNotificationCenter defaultCenter] removeObserver:obj];
        }];
        self.started = NO;
    }
    
}

- (void)addObserverWithName:(NSString *)name withBlock:(void (^)(NSNotification *note))block
{
    if ([name length]) {
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:self.notificationQueue usingBlock:block];
        if (observer) {
            [self removeNotificationObserversForName:name];
            [self.notificationObservers setObject:observer forKey:name];
        }
    }
}

- (void)removeNotificationObserversForName:(NSString *)name
{
    if ([name length]) {
        id observer = [self.notificationObservers objectForKey:name];
        if (observer) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
    }
}

- (UIViewController *)topViewController
{
    UIViewController *topController = [[UIApplication sharedApplication].delegate window].rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void)showLoginSuccessNotification:(NSNotification *)notification
{
    if (!self.enabled) {
        return;
    }
    UIViewController *topViewController = [self topViewController];
    if (![topViewController isKindOfClass:[OTRBaseLoginViewController class]]) {
        OTRXMPPManager *xmppManager = notification.object;
        NSString *accountName = nil;
        if (xmppManager) {
            accountName = [xmppManager accountName];
            accountName = [XMPPJID jidWithString:accountName].bare;
        }
        OTRToastOptions *options = [[OTRToastOptions alloc] initWithText:CONNECTED_STRING subtitleText:accountName optionType:OTRToastOptionTypeSuccess];
        [CRToastManager showNotificationWithOptions:[options dictionary] completionBlock:nil];
    }
}

- (void)showLoginFailureNotification:(NSNotification *)notification
{
    if (!self.enabled) {
        return;
    }
    BOOL isUserInitiated = [[notification.userInfo objectForKey:kOTRProtocolLoginUserInitiated] boolValue];
    
    UIViewController *topViewController = [self topViewController];
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        topViewController = ((UINavigationController *)topViewController).topViewController;
    }
    
    BOOL correctViewController = !([topViewController isKindOfClass:[OTRBaseLoginViewController class]] || [topViewController isKindOfClass:[OTRSettingsViewController class]]);
    
    
    if (correctViewController && isUserInitiated) {
        OTRXMPPManager *xmppManager = notification.object;
        NSString *accountName = nil;
        if (xmppManager) {
            accountName = [xmppManager accountName];
            accountName = [XMPPJID jidWithString:accountName].bare;
        }
        OTRToastOptions *options = [[OTRToastOptions alloc] initWithText:ACCOUNT_DISCONNECTED_STRING subtitleText:accountName optionType:OTRToastOptionTypeFailure];
        [CRToastManager showNotificationWithOptions:[options dictionary] completionBlock:nil];
    }
}

#pragma - mark Public Methods

- (void)showAccountConnectingNotificationWithAccountName:(NSString *)accountName
{
    if (!self.enabled) {
        return;
    }
    OTRToastOptions *options = [OTRToastOptions optionsWithText:CONNECTING_STRING subtitleText:accountName];
    options.image = [UIImage otr_imageWithImage:[OTRImages wifiWithColor:[UIColor whiteColor]] scaledToSize:kOTRDefaultNotificationImageSize];
    [CRToastManager showNotificationWithOptions:[options dictionary] completionBlock:nil];
}

#pragma - mark Class Methods

+ (instancetype)sharedInstance
{
    static id notifcationCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notifcationCenter = [[self alloc] init];
    });
    
    return notifcationCenter;
}

@end
