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

#import "OTRConstants.h"

#import "OTRUtilities.h"
#import "OTRAccountsManager.h"
#import "OTRSettingsManager.h"
@import OTRAssets;
#import "OTRDatabaseManager.h"
@import SAMKeychain;

#import "OTRLog.h"
@import CocoaLumberjack;
#import "OTRAccount.h"
#import "OTRXMPPAccount.h"
#import "OTRBuddy.h"
@import YapDatabase;

#import "OTRCertificatePinning.h"
#import "NSURL+ChatSecure.h"
#import "OTRDatabaseUnlockViewController.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRPasswordGenerator.h"
#import "UIViewController+ChatSecure.h"
@import XMPPFramework;
#import "OTRProtocolManager.h"
#import "OTRInviteViewController.h"
#import "ChatSecureCoreCompat-Swift.h"
#import "OTRMessagesViewController.h"
#import "OTRXMPPTorAccount.h"
@import OTRAssets;
@import OTRKit;
#if KSCRASH
#import <KSCrash/KSCrash.h>
#import <KSCrash/KSCrashInstallationQuincyHockey.h>
#import <KSCrash/KSCrashInstallation+Alert.h>
#endif
@import UserNotifications;

#import "OTRChatDemo.h"

@interface OTRAppDelegate ()

@property (nonatomic, strong) OTRSplitViewControllerDelegateObject *splitViewControllerDelegate;

@property (nonatomic, strong) NSTimer *fetchTimer;
@property (nonatomic, strong) NSTimer *backgroundTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation OTRAppDelegate
@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [LogManager.shared setupLogging];
    
    [self setupCrashReporting];
 
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    
    UIViewController *rootViewController = nil;
    
    // Create 3 primary view controllers, settings, conversation list and messages
    _conversationViewController = [GlobalTheme.shared conversationViewController];
    _messagesViewController = [GlobalTheme.shared messagesViewController];
    
    
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
        if ([[[NSProcessInfo processInfo] environment][@"OTRLaunchMode"] isEqualToString:@"ChatSecureUITestsDemoData"]) {
            [OTRChatDemo loadDemoChatInDatabase];
        } else if ([[[NSProcessInfo processInfo] environment][@"OTRLaunchMode"] isEqualToString:@"ChatSecureUITests"]) {
            [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                [transaction removeAllObjectsInAllCollections];
            }];
        }
    }
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = rootViewController;
    
    /////////// testing VCs
//    OTRXMPPAccount *account = [[OTRXMPPAccount alloc] init];
//    account.username = @"test@example.com";
//    OTRInviteViewController *vc = [[OTRInviteViewController alloc] initWithAccount:account];
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
//    self.window.rootViewController = nav;
    ////////////
    
    [self.window makeKeyAndVisible];
    [TransactionObserver.shared startObserving];
    
    if ([PushController getPushPreference] == PushPreferenceEnabled) {
        [PushController registerForPushNotifications];
    }
    
    [self autoLoginFromBackground:NO];
    [self configureBackgroundTasksWithApplication:application];

    // For disabling screen dimming while plugged in
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryStateDidChange:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [self batteryStateDidChange:nil];
    
    // Setup iOS 10+ in-app notifications
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }
    
    [application registerForRemoteNotifications];

    return YES;
}

- (void) setupCrashReporting {
//    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:[OTRSecrets hockeyLiveIdentifier]];
//    [[BITHockeyManager sharedHockeyManager].crashManager setCrashManagerStatus: BITCrashManagerStatusAlwaysAsk];
//    [[BITHockeyManager sharedHockeyManager] startManager];
    
#if KSCRASH
    KSCrash *crash = [KSCrash sharedInstance];
    crash.monitoring = KSCrashMonitorTypeProductionSafeMinimal;
    
//#warning Change this to KSCrashMonitorTypeProductionSafeMinimal before App Store release!
//#warning Otherwise it may crash for pauses longer than the deadlockWatchdogInterval!
    
    // People are reporting deadlocks again...
    // Let's turn this back on for a little while.
#if DEBUG
    crash.monitoring = KSCrashMonitorTypeNone;
#else
    //crash.monitoring = KSCrashMonitorTypeAll;
    //crash.deadlockWatchdogInterval = 20;
#endif
    
    // Setup Crash Reporting
    KSCrashInstallationHockey* installation = [KSCrashInstallationHockey sharedInstance];
    [installation addConditionalAlertWithTitle:Crash_Detected_Title()
                                       message:Crash_Detected_Message()
                                     yesAnswer:OK_STRING()
                                      noAnswer:CANCEL_STRING()];

    installation.appIdentifier = [OTRSecrets hockeyLiveIdentifier];
    
    [installation install];
    [installation sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error)
    {
        if (error) {
            NSLog(@"Error sending KSCrashInstallationHockey reports: %@", error);
        } else {
            NSLog(@"Sending %d KSCrashInstallationHockey reports.", (int)filteredReports.count);
        }
    }];
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
- (UIViewController *)setupDefaultSplitViewControllerWithLeadingViewController:(nonnull UIViewController *)leadingViewController
{
    
    YapDatabaseConnection *connection = [OTRDatabaseManager sharedInstance].writeConnection;
    _splitViewCoordinator = [[OTRSplitViewCoordinator alloc] initWithDatabaseConnection:connection];
    self.splitViewControllerDelegate = [[OTRSplitViewControllerDelegateObject alloc] init];
    self.conversationViewController.delegate = self.splitViewCoordinator;
    
    //MessagesViewController Nav
    UINavigationController *messagesNavigationController = [[UINavigationController alloc ]initWithRootViewController:self.messagesViewController];
    
    //SplitViewController
    UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
    splitViewController.viewControllers = @[leadingViewController,messagesNavigationController];
    splitViewController.delegate = self.splitViewControllerDelegate;
    splitViewController.title = CHAT_STRING();
    
    //setup 'back' button in nav bar
    messagesNavigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    messagesNavigationController.topViewController.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.splitViewCoordinator.splitViewController = splitViewController;
    
    return splitViewController;
}

- (void)showConversationViewController
{
    self.window.rootViewController = [self setupDefaultSplitViewControllerWithLeadingViewController:[[UINavigationController alloc] initWithRootViewController:self.conversationViewController]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [OTRAppDelegate setLastInteractionDate:NSDate.date];
    
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[OTRProtocolManager sharedInstance] goAwayForAllAccounts];
    DDLogInfo(@"Application entered background state.");
    NSAssert(self.backgroundTask == UIBackgroundTaskInvalid, nil);
    
    [self scheduleBackgroundTasksWithApplication:application completionHandler:nil];
    
    __block NSUInteger unread = 0;
    [[OTRDatabaseManager sharedInstance].readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        unread = [transaction numberOfUnreadMessages];
    } completionBlock:^{
        application.applicationIconBadgeNumber = unread;
//#if DEBUG
//        // Temporary hack to fix corrupted development database
//        if (unread > 0) {
//            [self fixUnreadMessageCount:^(NSUInteger count) {
//                application.applicationIconBadgeNumber = count;
//            }];
//        }
//#endif
    }];
    

    
    self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        DDLogInfo(@"Background task expired, disconnecting all accounts. Remaining: %f", application.backgroundTimeRemaining);
        if (self.backgroundTimer)
        {
            [self.backgroundTimer invalidate];
            self.backgroundTimer = nil;
        }
        [[OTRProtocolManager sharedInstance] disconnectAllAccountsSocketOnly:YES timeout:application.backgroundTimeRemaining - .5 completionBlock:^{
            [application endBackgroundTask:self.backgroundTask];
            self.backgroundTask = UIBackgroundTaskInvalid;
        }];
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
    });
}
                                
- (void) timerUpdate:(NSTimer*)timer {
    //UIApplication *application = [UIApplication sharedApplication];
    //NSTimeInterval timeRemaining = application.backgroundTimeRemaining;
    //DDLogVerbose(@"Timer update, background time left: %f", timeRemaining);
}

/** Doesn't stop autoLogin if previous crash when it's a background launch */
- (void)autoLoginFromBackground:(BOOL)fromBackground
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[OTRProtocolManager sharedInstance] loginAccounts:[OTRAccountsManager allAutoLoginAccounts]];
    });
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [OTRAppDelegate setLastInteractionDate:NSDate.date];
    [self autoLoginFromBackground:NO];
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [self batteryStateDidChange:nil];
    
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
    
    [UIApplication.sharedApplication removeExtraForegroundNotifications];
    [self resetFetchTimerWithResult:UIBackgroundFetchResultNewData];
}

/**
 If we have a fetch timer set, call the completion callback and invalidate the timer
 */
- (void)resetFetchTimerWithResult:(UIBackgroundFetchResult)result {
    if (self.fetchTimer) {
        if (self.fetchTimer.isValid) {
            NSDictionary *userInfo = self.fetchTimer.userInfo;
            void (^completion)(UIBackgroundFetchResult) = [userInfo objectForKey:@"completion"];
            // We should probbaly return accurate fetch results
            if (completion) {
                completion(result);
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
    // If we have an old fetch happening, call completion on that
    [self resetFetchTimerWithResult:UIBackgroundFetchResultNoData];
    
    if(application.applicationState == UIApplicationStateBackground) {
        [self autoLoginFromBackground:YES];

        self.fetchTimer = [NSTimer scheduledTimerWithTimeInterval:28.5 target:self selector:@selector(fetchTimerUpdate:) userInfo:@{@"completion": completionHandler} repeats:NO];
    } else {
        // Must call completion handler
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void) fetchTimerUpdate:(NSTimer*)timer {
    void (^completion)(UIBackgroundFetchResult) = timer.userInfo[@"completion"];
    NSTimeInterval timeout = [[UIApplication sharedApplication] backgroundTimeRemaining] - .5;

    [[OTRProtocolManager sharedInstance] disconnectAllAccountsSocketOnly:YES timeout:timeout completionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication.sharedApplication removeExtraForegroundNotifications];
            // We should probably return accurate fetch results
            if (completion) {
                completion(UIBackgroundFetchResultNewData);
            }
        });
    }];
    self.fetchTimer = nil;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self scheduleBackgroundTasksWithApplication:application completionHandler:completionHandler];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        if ([url otr_isInviteLink]) {
            __block XMPPJID *jid = nil;
            __block NSString *fingerprint = nil;
            NSString *otr = [OTRAccount fingerprintStringTypeForFingerprintType:OTRFingerprintTypeOTR];
            [url otr_decodeShareLink:^(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) {
                jid = inJid;
                [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.name isEqualToString:otr]) {
                        fingerprint = obj.value;
                        *stop = YES;
                    }
                }];
            }];
            if (jid) {
                [OTRProtocolManager handleInviteForJID:jid otrFingerprint:fingerprint buddyAddedCallback:nil];
            }
            return YES;
        }
    }
    return NO;
}

- (BOOL) application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([url.scheme isEqualToString:@"xmpp"]) {
        XMPPURI *xmppURI = [[XMPPURI alloc] initWithURL:url];
        XMPPJID *jid = xmppURI.jid;
        NSString *otrFingerprint = xmppURI.queryParameters[@"otr-fingerprint"];
        // NSString *action = xmppURI.queryAction; //  && [action isEqualToString:@"subscribe"]
        if (jid) {
            [OTRProtocolManager handleInviteForJID:jid otrFingerprint:otrFingerprint buddyAddedCallback:^ (OTRBuddy *buddy) {
                OTRXMPPBuddy *xmppBuddy = (OTRXMPPBuddy *)buddy;
                if (xmppBuddy != nil) {
                    [self enterThreadWithKey:xmppBuddy.threadIdentifier collection:xmppBuddy.threadCollection];
                }
            }];
            return YES;
        }
    }
    return NO;
}

- (void) showSubscriptionRequestForBuddy:(NSDictionary*)userInfo {
    // This is probably in response to a user requesting subscriptions from us
    [self.splitViewCoordinator showConversationsViewController];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData *)deviceToken
{
    [OTRProtocolManager.pushController didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    DDLogError(@"Error in registration. Error: %@%@", [err localizedDescription], [err userInfo]);
}

// To improve usability, keep the app open when you're plugged in
- (void) batteryStateDidChange:(NSNotification*)notification {
    UIDeviceBatteryState currentState = [[UIDevice currentDevice] batteryState];
    if (currentState == UIDeviceBatteryStateCharging || currentState == UIDeviceBatteryStateFull) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    } else {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

#pragma - mark Class Methods
+ (instancetype)appDelegate
{
    return (OTRAppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark - Theming

- (void) setupTheme { }

@end
