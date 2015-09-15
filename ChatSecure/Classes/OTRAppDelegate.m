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
#import "Strings.h"
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
#import "UIAlertView+Blocks.h"
#import "XMPPURI.h"
#import "OTRProtocolManager.h"
#import "OTRInviteViewController.h"

#if CHATSECURE_DEMO
#import "OTRChatDemo.h"
#endif

@interface OTRAppDelegate ()


@end

@implementation OTRAppDelegate

@synthesize window = _window;
@synthesize backgroundTask, backgroundTimer, didShowDisconnectionWarning;
@synthesize settingsViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:kOTRHockeyBetaIdentifier
                                                         liveIdentifier:kOTRHockeyLiveIdentifier
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    [OTRCertificatePinning loadBundledCertificatesToKeychain];
    
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    
    UIViewController *rootViewController = nil;
    
    self.settingsViewController = [[OTRSettingsViewController alloc] init];
    self.conversationViewController = [[OTRConversationViewController alloc] init];
    self.messagesViewController = [OTRMessagesHoldTalkViewController messagesViewController];
    
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
        rootViewController = [self defaultConversationNavigationController];
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
  
    [Appirater setAppId:@"464200063"];
    [Appirater setOpenInAppStore:NO];
    [Appirater appLaunched:YES];
    
    [self autoLogin];
    
    [self removeFacebookAccounts];
        
    return YES;
}

- (void) loadDemoData {
#if CHATSECURE_DEMO
    [OTRChatDemo loadDemoChatInDatabase];
#endif
}

- (UIViewController*)defaultConversationNavigationController
{
    UIViewController *viewController = nil;
    
    //ConversationViewController Nav
    UINavigationController *conversationListNavController = [[UINavigationController alloc] initWithRootViewController:self.conversationViewController];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        viewController = conversationListNavController;
    } else {
        //MessagesViewController Nav
        UINavigationController *messagesNavController = [[UINavigationController alloc ]initWithRootViewController:self.messagesViewController];
        
        //SplitViewController
        UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
        splitViewController.viewControllers = [NSArray arrayWithObjects:conversationListNavController, messagesNavController, nil];
        splitViewController.delegate = self.messagesViewController;
        splitViewController.title = CHAT_STRING;
        
        viewController = splitViewController;
    }
    
    return viewController;
}

- (void)showConversationViewController
{
    self.window.rootViewController = [self defaultConversationNavigationController];
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
            
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:FACEBOOK_REMOVED_STRING message:FACEBOOK_REMOVED_MESSAGE_STRING preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:OK_STRING style:UIAlertActionStyleDefault handler:nil];
                UIAlertAction *moreInfoAction = [UIAlertAction actionWithTitle:INFO_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    moreInfoBlock();
                }];
                
                [alertController addAction:okAction];
                [alertController addAction:moreInfoAction];
                
                [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
                
            } else {
                RIButtonItem *okButtonItem = [RIButtonItem itemWithLabel:OK_STRING];
                RIButtonItem *moreInfoButtonItem = [RIButtonItem itemWithLabel:INFO_STRING action:^{
                    moreInfoBlock();
                }];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:FACEBOOK_REMOVED_STRING message:FACEBOOK_REMOVED_MESSAGE_STRING cancelButtonItem:nil otherButtonItems:okButtonItem,moreInfoButtonItem, nil];
                [alertView show];
            }
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
        application.applicationIconBadgeNumber = [OTRMessage numberOfUnreadMessagesWithTransaction:transaction];
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
        self.backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
    });
}
                                
- (void) timerUpdate:(NSTimer*)timer {
    UIApplication *application = [UIApplication sharedApplication];

    DDLogInfo(@"Timer update, background time left: %f", application.backgroundTimeRemaining);
    
    if ([application backgroundTimeRemaining] < 60 && !self.didShowDisconnectionWarning && [OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyShowDisconnectionWarning]) 
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
    if ([application backgroundTimeRemaining] < 10)
    {
        // Clean up here
        [self.backgroundTimer invalidate];
        self.backgroundTimer = nil;
        
        [[OTRProtocolManager sharedInstance] disconnectAllAccounts];
        //FIXME [OTRManagedAccount resetAccountsConnectionStatus];
        
        
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)autoLogin
{
    //Auto Login
    if (![BITHockeyManager sharedHockeyManager].crashManager.didCrashInLastSession) {
        [[OTRProtocolManager sharedInstance] loginAccounts:[OTRAccountsManager allAutoLoginAccounts]];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [Appirater appEnteredForeground:YES];
    [self autoLogin];
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
/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    NSString *buddyUniqueId = userInfo[kOTRNotificationBuddyUniqueIdKey];
    
    if([buddyUniqueId length]) {
        __block OTRBuddy *buddy = nil;
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [OTRBuddy fetchObjectWithUniqueID:buddyUniqueId transaction:transaction];
        }];
        
        if (!([self.messagesViewController otr_isVisible] || [self.conversationViewController otr_isVisible])) {
            self.window.rootViewController = [self defaultConversationNavigationController];
        }
        
        [self.conversationViewController enterConversationWithBuddy:buddy];
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
            NSString *message = jid.full;
            if (otrFingerprint.length == 40) {
                message = [message stringByAppendingFormat:@"\n%@", otrFingerprint];
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:ADD_BUDDY_STRING message:message preferredStyle:UIAlertControllerStyleActionSheet];
            __block NSArray *accounts = nil;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                accounts = [OTRAccount allAccountsWithTransaction:transaction];
            }];
            [accounts enumerateObjectsUsingBlock:^(OTRAccount *account, NSUInteger idx, BOOL *stop) {
                if ([account isKindOfClass:[OTRXMPPAccount class]]) {
                    UIAlertAction *action = [UIAlertAction actionWithTitle:account.username style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:account];
                        OTRBuddy *buddy = [[OTRBuddy alloc] init];
                        buddy.username = jid.full;
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
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:CANCEL_STRING style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancel];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
        return YES;
    }
    return NO;
}

// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    
    
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    [[NSNotificationCenter defaultCenter] postNotificationName:OTRFailedRemoteNotificationRegistration object:self userInfo:@{kOTRNotificationErrorKey:err}];
    DDLogError(@"Error in registration. Error: %@%@", [err localizedDescription], [err userInfo]);
}

#pragma - mark Class Methods
+ (OTRAppDelegate *)appDelegate
{
    return (OTRAppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end
