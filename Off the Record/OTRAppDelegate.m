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

#import "OTRBuddyListViewController.h"
#import "OTRChatViewController.h"
#import "Strings.h"
#import "OTRSettingsViewController.h"
#import "OTRSettingsManager.h"

#import "Appirater.h"
#import "OTRConstants.h"
#import "OTRLanguageManager.h"
#import "OTRConvertAccount.h"
#import "OTRUtilities.h"
#import "OTRAccountsManager.h"
#import "FacebookSDK.h"
#import "OTRAppVersionManager.h"
#import "OTRSettingsManager.h"
#import "OTRSecrets.h"
#import "OTRDatabaseManager.h"

#import "OTRDemoChatViewController.h"
#import "SSKeychain.h"

#import "OTRLog.h"
#import "DDTTYLogger.h"

@implementation OTRAppDelegate

@synthesize window = _window;
@synthesize backgroundTask, backgroundTimer, didShowDisconnectionWarning;
@synthesize settingsViewController, buddyListViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:HOCKEY_BETA_IDENTIFIER
                                                         liveIdentifier:HOCKEY_LIVE_IDENTIFIER
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];

    NSString *outputStoreName = @"ChatSecure.sqlite";
    [OTRDatabaseManager setupDatabaseWithName:outputStoreName];
    
    //CONVERT LEGACY ACCOUNT DICTIONARIES
    OTRConvertAccount * accountConverter = [[OTRConvertAccount alloc] init];
    if ([accountConverter hasLegacyAccountSettings]) {
        [accountConverter convertAllLegacyAcountSettings];
    }
    
    [OTRUtilities deleteAllBuddiesAndMessages];
    
    [OTRManagedAccount resetAccountsConnectionStatus];
    
    [OTRAppVersionManager applyAppUpdatesForCurrentAppVersion];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.buddyListViewController = [[OTRBuddyListViewController alloc] init];
    //OTRChatViewController *chatViewController = [[OTRDemoChatViewController alloc] init];
    OTRChatViewController *chatViewController = [[OTRChatViewController alloc] init];
    buddyListViewController.chatViewController = chatViewController;
    self.settingsViewController = [[OTRSettingsViewController alloc] init];

    UINavigationController *buddyListNavController = [[UINavigationController alloc] initWithRootViewController:buddyListViewController];
    UIViewController *rootViewController = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        rootViewController = buddyListNavController;
    } else {
        UINavigationController *chatNavController = [[UINavigationController alloc ]initWithRootViewController:chatViewController];
        UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
        splitViewController.viewControllers = [NSArray arrayWithObjects:buddyListNavController, chatNavController, nil];
        splitViewController.delegate = chatViewController;
        rootViewController = splitViewController;
        splitViewController.title = CHAT_STRING;
    }

    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    application.applicationIconBadgeNumber = 0;
  
    [Appirater setAppId:@"464200063"];
    [Appirater setOpenInAppStore:NO];
    [Appirater appLaunched:YES];
    
    [self autoLogin];
        
    return YES;
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
        
        OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
        for(id key in protocolManager.protocolManagers)
        {
            id <OTRProtocol> protocol = [protocolManager.protocolManagers objectForKey:key];
            [protocol disconnect];
        }
        [OTRManagedAccount resetAccountsConnectionStatus];
        
        
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
    [OTRManagedAccount resetAccountsConnectionStatus];
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    
    
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    
    for(id key in [protocolManager.protocolManagers allKeys])
    {
        id <OTRProtocol> protocol = [protocolManager.protocolManagers objectForKey:key];
        [protocol disconnect];
    }
    [OTRManagedAccount resetAccountsConnectionStatus];
    [OTRUtilities deleteAllBuddiesAndMessages];
    
    [MagicalRecord cleanUp];
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
    //DDLogInfo(@"Notification Body: %@", notification.alertBody);
    //DDLogInfo(@"User Info: %@", notification.userInfo);
    
    NSDictionary *userInfo = notification.userInfo;
    NSString *accountName = [userInfo objectForKey:kOTRNotificationAccountNameKey];
    NSString *userName = [userInfo objectForKey:kOTRNotificationUserNameKey];
    NSString *protocol = [userInfo objectForKey:kOTRNotificationProtocolKey];
    if (!accountName || !userName || !protocol) {
        return;
    }
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    OTRManagedBuddy *buddy = [protocolManager buddyForUserName:userName accountName:accountName protocol:protocol];
    [buddyListViewController enterConversationWithBuddy:buddy];
}

- (void) presentActionSheet:(UIActionSheet*)sheet inView:(UIView*)view {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [sheet showInView:view];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [sheet showInView:self.window];
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[FBSession activeSession] handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FBSession activeSession] handleOpenURL:url];
}

@end
