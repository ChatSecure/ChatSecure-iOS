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
#import "DDLog.h"
#import "OTRUIKeyboardListener.h"
#import "Appirater.h"
#import "OTRConstants.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

// If you downloaded this source from Github delete the
// CRITTERCISM_ENABLED key in the Preprocessor Macros
// section of the project file to compile the project without
// error reporting support.
#ifdef CRITTERCISM_ENABLED
#import "Crittercism.h"
#import "OTRCrittercismSecrets.h"
#endif

@implementation OTRAppDelegate

@synthesize window = _window;
@synthesize backgroundTask, backgroundTimer, didShowDisconnectionWarning;
@synthesize settingsViewController, buddyListViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef CRITTERCISM_ENABLED
    if([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyCrittercismOptIn])
    {
        [Crittercism initWithAppID:CRITTERCISM_APP_ID
                            andKey:CRITTERCISM_KEY
                         andSecret:CRITTERCISM_SECRET];
        [Crittercism setOptOutStatus:NO];
    } 
    else 
    {
        [Crittercism setOptOutStatus:YES];
    }
#endif

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.buddyListViewController = [[OTRBuddyListViewController alloc] init];
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
    [OTRUIKeyboardListener shared];
  
    [Appirater appLaunched:YES];
    
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
    NSLog(@"Application entered background state.");
    NSAssert(self.backgroundTask == UIBackgroundTaskInvalid, nil);
    self.didShowDisconnectionWarning = NO;
    
    self.backgroundTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Background task expired");
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

    NSLog(@"Timer update, background time left: %f", application.backgroundTimeRemaining);
    
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
        [application endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    NSLog(@"Application became active");
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
    
    for(id key in protocolManager.protocolManagers)
    {
        id <OTRProtocol> protocol = [protocolManager.protocolManagers objectForKey:key];
        [protocol disconnect];
    }
    
    /*
    NSPersistentStoreCoordinator *storeCoordinator = [protocolManager.xmppManager.xmppRosterStorage
 persistentStoreCoordinator];
     NSArray *stores = [storeCoordinator persistentStores];
     
     for(NSPersistentStore *store in stores)
     {
     NSError *error = nil;
     NSError *error2 = nil;
     NSURL *storeURL = store.URL;
     [storeCoordinator removePersistentStore:store error:&error];
     [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
     if(error)
     NSLog(@"%@",[error description]);
     if(error2)
     NSLog(@"%@",[error2 description]);
     }
     */
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
    //NSLog(@"Notification Body: %@", notification.alertBody);
    //NSLog(@"User Info: %@", notification.userInfo);
    
    NSDictionary *userInfo = notification.userInfo;
    NSString *accountName = [userInfo objectForKey:kOTRNotificationAccountNameKey];
    NSString *userName = [userInfo objectForKey:kOTRNotificationUserNameKey];
    NSString *protocol = [userInfo objectForKey:kOTRNotificationProtocolKey];
    if (!accountName || !userName || !protocol) {
        return;
    }
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    OTRBuddy *buddy = [protocolManager buddyForUserName:userName accountName:accountName protocol:protocol];
    [buddyListViewController enterConversationWithBuddy:buddy];
}

- (void) presentActionSheet:(UIActionSheet*)sheet inView:(UIView*)view {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [sheet showInView:view];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [sheet showInView:self.window];
    }
}

@end
