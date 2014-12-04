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
#import "OTRLoginViewController.h"
#import "OTRXMPPManager.h"
#import "OTRToastOptions.h"

@interface OTRNotificationController ()

@property (nonatomic, strong) NSOperationQueue *notificationQueue;
@property (nonatomic, strong) NSMutableDictionary *notificationObservers;

@end

@implementation OTRNotificationController


- (instancetype)init
{
    if (self = [super init]) {
        
        self.notificationQueue = [NSOperationQueue mainQueue];
        self.notificationObservers = [NSMutableDictionary new];
        
        __weak typeof(self)weakSelf = self;
        [self addObserverWithName:kOTRProtocolLoginSuccess withBlock:^(NSNotification *note) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf showLoginSuccessNotification:note];
        }];
        
        [self addObserverWithName:kOTRProtocolLoginFail withBlock:^(NSNotification *note) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf showLoginFailureNotification:note];
        }];
        
        
    }
    return self;
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
    return [[UIApplication sharedApplication].delegate window].rootViewController;
}

- (void)showLoginSuccessNotification:(NSNotification *)notification
{
    UIViewController *topViewController = [self topViewController];
    if (![topViewController isKindOfClass:[OTRLoginViewController class]]) {
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
    UIViewController *topViewController = [self topViewController];
    if (![topViewController isKindOfClass:[OTRLoginViewController class]]) {
        //[CRToastManager showNotificationWithMessage:@"Login Bad" completionBlock:nil];
    }
}

#pragma - mark Public Methods

- (void)showAccountConnectingNotificationWithAccountName:(NSString *)accountName
{
    OTRToastOptions *options = [OTRToastOptions optionsWithText:CONNECTING_STRING subtitleText:accountName];
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
