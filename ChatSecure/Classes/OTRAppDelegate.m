//
//  OTRAppDelegate.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRAppDelegate.h"

#import "OTRConversationViewController.h"

#import "OTRMessagesHoldTalkViewController.h"
#import "OTRSettingsViewController.h"
#import "OTRSettingsManager.h"

#import "Appirater.h"
#import "OTRConstants.h"
#import "OTRLanguageManager.h"
#import "OTRUtilities.h"
#import "OTRAccountsManager.h"
#import "OTRSettingsManager.h"
#import "OTRSecrets.h"
#import "OTRDatabaseManager.h"
#import <SSKeychain/SSKeychain.h>

#import "OTRLog.h"
#import "DDTTYLogger.h"
#import "OTRAccount.h"
#import "OTRXMPPAccount.h"
#import "OTRBuddy.h"
@import YapDatabase;

#import "OTRCertificatePinning.h"
#import "NSData+XMPP.h"
#import "NSURL+ChatSecure.h"
#import "OTRDatabaseUnlockViewController.h"
#import "OTRMessage.h"
#import "OTRPasswordGenerator.h"
#import "UIViewController+ChatSecure.h"
#import "OTRNotificationController.h"
#import "XMPPURI.h"
#import "OTRProtocolManager.h"
#import "OTRInviteViewController.h"
#import "OTRTheme.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRMessagesViewController.h"
@import OTRAssets;

#if CHATSECURE_DEMO
#import "OTRChatDemo.h"
#endif

@interface OTRAppDelegate ()

@property (nonatomic, strong) OTRSplitViewCoordinator *splitViewCoordinator;
@property (nonatomic, strong) OTRSplitViewControllerDelegateObject *splitViewControllerDelegate;

@property (nonatomic, strong) NSTimer *fetchTimer;

@end

@implementation OTRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:[OTRSecrets hockeyBetaIdentifier]
                                                         liveIdentifier:[OTRSecrets hockeyLiveIdentifier]
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    _theme = [[[self themeClass] alloc] init];
    [self.theme setupGlobalTheme];
    
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    
    UIViewController *rootViewController = nil;
    
    // Create 3 primary view controllers, settings, conversation list and messages
    self.settingsViewController = [[OTRSettingsViewController alloc] init];
    self.conversationViewController = [[[self.theme conversationViewControllerClass] alloc] init];
    self.messagesViewController = [[self.theme messagesViewControllerClass] messagesViewController];
    
    
    if ([OTRDatabaseManager existsYapDatabase] && ![[OTRDatabaseManager sharedInstance] hasPassphrase]) {
        // user needs to enter password for current database
        rootViewController = [[OTRDatabaseUnlockViewController alloc] init];
    } else {
        ////// Normal launch to conversationViewController //////
        if (![OTRDatabaseManager existsYapDatabase]) {
            /**
             First Launch
             Create password and save to keychain
             **/
            NSString *newPassword = [OTRPasswordGenerator passwordWithLength:OTRDefaultPasswordLength];
            NSError *error = nil;
            [[OTRDatabaseManager sharedInstance] setDatabasePassphrase:newPassword remember:YES error:&error];
            if (error) {
                DDLogError(@"Password Error: %@",error);
            }
        }

        [[OTRDatabaseManager sharedInstance] setupDatabaseWithName:OTRYapDatabaseName];
        rootViewController = [self setupDefaultSplitViewControllerWithLeadingViewController:[[UINavigationController alloc] initWithRootViewController:self.conversationViewController]];
#if CHATSECURE_DEMO
        [self performSelector:@selector(loadDemoData) withObject:nil afterDelay:0.0];
#endif
    }
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = rootViewController;

    /*
    /////////// testing invite VC
    OTRInviteViewController *inviteVC = [[OTRInviteViewController alloc] init];
    OTRAccount *account = [[OTRAccount alloc] init];
    account.username = @"test@example.com";
    inviteVC.account = account;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:inviteVC];
    self.window.rootViewController = nav;
    ////////////
    */
     
    [self.window makeKeyAndVisible];
    
    application.applicationIconBadgeNumber = 0;
    
    OTRNotificationController *notificationController = [OTRNotificationController sharedInstance];
    [notificationController start];
    
    if ([PushController getPushPreference] == PushPreferenceEnabled) {
        [PushController registerForPushNotifications];
    }
  
    [Appirater setAppId:@"464200063"];
    [Appirater setOpenInAppStore:NO];
    [Appirater appLaunched:YES];
    
    
    ////// Reset buddy status //////
    OTRDatabaseManager *databaseManager = [OTRDatabaseManager sharedInstance];
    [databaseManager.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [OTRBuddy resetAllBuddyStatusesWithTransaction:transaction];
        [OTRBuddy resetAllChatStatesWithTransaction:transaction];
    }];
    
    [self autoLoginFromBackground:NO];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [self removeFacebookAccounts];
        
    return YES;
}

- (void) loadDemoData {
#if CHATSECURE_DEMO
    [OTRChatDemo loadDemoChatInDatabase];
#endif
}

/**
 * This creates a UISplitViewController using a leading view controller (the left view controller). It uses a navigation controller with
 * self.messagesViewController as teh right view controller;
 * This also creates and sets up teh OTRSplitViewCoordinator
 *
 * @param leadingViewController The leading or left most view controller in a UISplitViewController. Should most likely be some sort of UINavigationViewController
 * @return The base default UISplitViewController
 *
 */
- (UISplitViewController *)setupDefaultSplitViewControllerWithLeadingViewController:(nonnull UIViewController *)leadingViewController
{
    
    YapDatabaseConnection *connection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
    self.splitViewCoordinator = [[OTRSplitViewCoordinator alloc] initWithDatabaseConnection:connection];
    self.splitViewControllerDelegate = [[OTRSplitViewControllerDelegateObject alloc] init];
    self.conversationViewController.delegate = self.splitViewCoordinator;
    
    //MessagesViewController Nav
    self.messagesNavigationController = [[UINavigationController alloc ]initWithRootViewController:self.messagesViewController];
    
    //SplitViewController
    UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
    splitViewController.viewControllers = @[leadingViewController,self.messagesNavigationController];
    splitViewController.delegate = self.splitViewControllerDelegate;
    splitViewController.title = CHAT_STRING;
    
    //setup 'back' button in nav bar
    self.messagesNavigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    self.messagesNavigationController.topViewController.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.splitViewCoordinator.splitViewController = splitViewController;
    
    return splitViewController;
}

- (void)showConversationViewController
{
    self.window.rootViewController = [self setupDefaultSplitViewControllerWithLeadingViewController:[[UINavigationController alloc] initWithRootViewController:self.conversationViewController]];
}

- (id<OTRThreadOwner>)activeThread
{
    __block id<OTRThreadOwner> threadOwner = nil;
    NSArray <UIViewController *>*viewControllers = [self.splitViewCoordinator.splitViewController viewControllers];
    [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray <UIViewController *>*result = nil;
        if ([obj isKindOfClass:[UINavigationController class] ]) {
            result = [((UINavigationController *)obj) otr_baseViewContorllers];
        } else {
            result = @[obj];
        }
        
        [result enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj isKindOfClass:[OTRMessagesViewController class]] && [obj otr_isVisible])
            {
                OTRMessagesViewController *messagesViewController = (OTRMessagesViewController *)obj;
                threadOwner = [messagesViewController threadObject];
                *stop = YES;
            }
        }];
        
        if (threadOwner) {
            *stop = YES;
        }
    }];
    return threadOwner;
}

- (void)removeFacebookAccounts
{
    NSNumber *deleted = [[NSUserDefaults standardUserDefaults] objectForKey:kOTRDeletedFacebookKey];
    
    if (deleted.boolValue) {
        return;
    }
    
    __block NSUInteger deletedAccountsCount = 0;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        deletedAccountsCount = [OTRAccount removeAllAccountsOfType:OTRAccountTypeFacebook inTransaction:transaction];
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:kOTRDeletedFacebookKey];
        
    } completionQueue:dispatch_get_main_queue() completionBlock:^{
        if (deletedAccountsCount > 0) {
            
            void (^moreInfoBlock)(void) = ^void(void) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://developers.facebook.com/docs/chat"]];
            };
        
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:FACEBOOK_REMOVED_STRING message:FACEBOOK_REMOVED_MESSAGE_STRING preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleDefault handler:nil];
            UIAlertAction *moreInfoAction = [UIAlertAction actionWithTitle:INFO_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                moreInfoBlock();
            }];
            
            [alertController addAction:okAction];
            [alertController addAction:moreInfoAction];
            
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DDLogInfo(@"Application entered background state.");
    NSAssert(self.backgroundTask == UIBackgroundTaskInvalid, nil);
    
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        application.applicationIconBadgeNumber = [transaction numberOfUnreadMessages];
    }];
    
    self.didShowDisconnectionWarning = NO;
    
    self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogInfo(@"Background task expired");
            if (self.backgroundTimer) 
            {
                [self.backgroundTimer invalidate];
                self.backgroundTimer = nil;
            }
            [application endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        });
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
    });
}
                                
- (void) timerUpdate:(NSTimer*)timer {
    UIApplication *application = [UIApplication sharedApplication];

    NSTimeInterval timeRemaining = application.backgroundTimeRemaining;
    DDLogVerbose(@"Timer update, background time left: %f", timeRemaining);
    
    if (timeRemaining < 60 && !self.didShowDisconnectionWarning && [OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyShowDisconnectionWarning])
    {
        UILocalNotification *localNotif = [[UILocalNotification alloc] init];
        if (localNotif) {
            localNotif.alertBody = EXPIRATION_STRING;
            localNotif.alertAction = OK_STRING;
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            [application presentLocalNotificationNow:localNotif];
        }
        self.didShowDisconnectionWarning = YES;
    }
    if (timeRemaining < 3)
    {
        // Clean up here
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
        
        [[OTRProtocolManager sharedInstance] disconnectAllAccountsSocketOnly:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [application endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        });
    }
}

/** Doesn't stop autoLogin if previous crash when it's a background launch */
- (void)autoLoginFromBackground:(BOOL)fromBackground
{
    //Auto Login
    if (![BITHockeyManager sharedHockeyManager].crashManager.didCrashInLastSession
        || fromBackground) {
        [[OTRProtocolManager sharedInstance] loginAccounts:[OTRAccountsManager allAutoLoginAccounts]];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [Appirater appEnteredForeground:YES];
    [self autoLoginFromBackground:NO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    DDLogInfo(@"Application became active");
    
    if (self.backgroundTimer) 
    {
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
    }
    if (self.backgroundTask != UIBackgroundTaskInvalid) 
    {
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
    //FIXME? [OTRManagedAccount resetAccountsConnectionStatus];
    application.applicationIconBadgeNumber = 0;
    
    if (self.fetchTimer) {
        if (self.fetchTimer.isValid) {
            NSDictionary *userInfo = self.fetchTimer.userInfo;
            void (^completion)(UIBackgroundFetchResult) = [userInfo objectForKey:@"completion"];
            // We should probbaly return accurate fetch results
            if (completion) {
                completion(UIBackgroundFetchResultNewData);
            }
            [self.fetchTimer invalidate];
        }
        self.fetchTimer = nil;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    
    
    [[OTRProtocolManager sharedInstance] disconnectAllAccounts];
    
    //FIXME? [OTRManagedAccount resetAccountsConnectionStatus];
    //[OTRUtilities deleteAllBuddiesAndMessages];
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self autoLoginFromBackground:YES];
    
    self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:28.5 target:self selector:@selector(fetchTimerUpdate:) userInfo:@{@"completion": completionHandler} repeats:NO];
}

- (void) fetchTimerUpdate:(NSTimer*)timer {
    [[OTRProtocolManager sharedInstance] disconnectAllAccountsSocketOnly:YES];
    NSDictionary *userInfo = timer.userInfo;
    void (^completion)(UIBackgroundFetchResult) = [userInfo objectForKey:@"completion"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // We should probbaly return accurate fetch results
        if (completion) {
            completion(UIBackgroundFetchResultNewData);
        }
    });
    self.fetchTimer = nil;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self application:application performFetchWithCompletionHandler:completionHandler];
    
    [self.pushController receiveRemoteNotification:userInfo completion:^(OTRBuddy * _Nullable buddy, NSError * _Nullable error) {
        // Only show notification if buddy lookup succeeds
        if (buddy) {
            [application showLocalNotificationForKnockFrom:buddy];
        }
    }];
}

- (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        if ([url otr_isInviteLink]) {
            __block NSString *username = nil;
            __block NSString *fingerprint = nil;
            [url otr_decodeShareLink:^(NSString *uName, NSString *fPrint) {
                username = uName;
                fingerprint = fPrint;
            }];
            if (username.length) {
                [self handleInvite:username fingerprint:fingerprint];
            }
            return YES;
        }
    }
    return NO;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    NSString *threadKey = userInfo[kOTRNotificationThreadKey];
    NSString *threadCollection = userInfo[kOTRNotificationThreadCollection];
    
    __block id <OTRThreadOwner> thread = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        thread = [transaction objectForKey:threadKey inCollection:threadCollection];
    }];
    
    if (thread) {
        [self.splitViewCoordinator enterConversationWithThread:thread sender:notification];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[BITHockeyManager sharedHockeyManager].authenticator handleOpenURL:url
                                                          sourceApplication:sourceApplication
                                                                 annotation:annotation]) {
        return YES;
    }
    if ([url.scheme isEqualToString:@"xmpp"]) {
        XMPPURI *xmppURI = [[XMPPURI alloc] initWithURL:url];
        XMPPJID *jid = xmppURI.jid;
        NSString *otrFingerprint = xmppURI.queryParameters[@"otr-fingerprint"];
        NSString *action = xmppURI.queryAction;
        if (jid && [action isEqualToString:@"subscribe"]) {
            [self handleInvite:jid.full fingerprint:otrFingerprint];
        }
        return YES;
    }
    return NO;
}

- (void)handleInvite:(NSString *)jidString fingerprint:(NSString *)otrFingerprint {
    NSString *message = [NSString stringWithString:jidString];
    if (otrFingerprint.length == 40) {
        message = [message stringByAppendingFormat:@"\n%@", otrFingerprint];
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:ADD_BUDDY_STRING message:message preferredStyle:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? UIAlertControllerStyleActionSheet : UIAlertControllerStyleAlert];
    __block NSArray *accounts = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        accounts = [OTRAccount allAccountsWithTransaction:transaction];
    }];
    [accounts enumerateObjectsUsingBlock:^(OTRAccount *account, NSUInteger idx, BOOL *stop) {
        if ([account isKindOfClass:[OTRXMPPAccount class]]) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:account.username style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
                OTRBuddy *buddy = [[OTRBuddy alloc] init];
                buddy.username = jidString;
                [protocol addBuddy:buddy];
                /* TODO OTR fingerprint verificaction
                 if (otrFingerprint) {
                 // We are missing a method to add fingerprint to trust store
                 [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:buddy.username accountName:account.username protocol:account.protocolTypeString verified:YES completion:nil];
                 }*/
            }];
            [alert addAction:action];
        }
    }];
    if (alert.actions.count > 0) {
        // No need to show anything if only option is "cancel"
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:CANCEL_STRING style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OTRUserNotificationsChanged object:self userInfo:@{@"settings": notificationSettings}];
    if (notificationSettings.types == UIUserNotificationTypeNone) {
        NSLog(@"Push notifications disabled by user.");
    } else {
        [application registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
{
    [self.pushController didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    [[NSNotificationCenter defaultCenter] postNotificationName:OTRFailedRemoteNotificationRegistration object:self userInfo:@{kOTRNotificationErrorKey:err}];
    DDLogError(@"Error in registration. Error: %@%@", [err localizedDescription], [err userInfo]);
}

#pragma - mark Getters and Setters

- (PushController *)pushController{
    if (!_pushController) {
        NSURL *pushAPIEndpoint = [OTRBranding pushAPIURL];
        OTRPushTLVHandler *tlvHandler = [OTRProtocolManager sharedInstance].encryptionManager.pushTLVHandler;
        _pushController = [[PushController alloc] initWithBaseURL:pushAPIEndpoint sessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] databaseConnection:[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection tlvHandler:tlvHandler];

    }
    return _pushController;
}

#pragma - mark Class Methods
+ (OTRAppDelegate *)appDelegate
{
    return (OTRAppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Theming

- (Class) themeClass {
    return [OTRTheme class];
}

@end
