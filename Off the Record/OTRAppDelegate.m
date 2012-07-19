//
//  OTRAppDelegate.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRAppDelegate.h"

#import "OTRBuddyListViewController.h"
#import "OTRChatListViewController.h"
#import "OTRAccountsViewController.h"
#import "OTRChatViewController.h"
#import "Strings.h"
#import "OTRSettingsViewController.h"
#import "OTRSettingsManager.h"
#import "DDLog.h"
#import "OTRUIKeyboardListener.h"
#import "Appirater.h"

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
@synthesize tabBarController = _tabBarController;
@synthesize backgroundTask, backgroundTimer, didShowDisconnectionWarning;

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
    UITabBarController *tabBarController = nil;
    
    OTRBuddyListViewController *buddyListViewController = [[OTRBuddyListViewController alloc] init];
    OTRChatViewController *chatViewController = [[OTRChatViewController alloc] init];
    buddyListViewController.chatViewController = chatViewController;
    OTRChatListViewController *chatListViewController = [[OTRChatListViewController alloc] init];
    //OTRAccountsViewController *accountsViewController = [[OTRAccountsViewController alloc] init];
    OTRSettingsViewController *settingsViewController = [[OTRSettingsViewController alloc] init];

    chatListViewController.buddyController = buddyListViewController;
    buddyListViewController.chatListController = chatListViewController;
    buddyListViewController.tabController = _tabBarController;
    tabBarController = [[UITabBarController alloc] init];
    UINavigationController *accountsNavController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    UINavigationController *buddyListNavController = [[UINavigationController alloc] initWithRootViewController:buddyListViewController];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        UINavigationController *chatListNavController = [[UINavigationController alloc] initWithRootViewController:chatListViewController];
        tabBarController.viewControllers = [NSArray arrayWithObjects:buddyListNavController, chatListNavController, accountsNavController, nil];
    } else {
        UINavigationController *chatNavController = [[UINavigationController alloc ]initWithRootViewController:chatViewController];
        UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
        splitViewController.viewControllers = [NSArray arrayWithObjects:buddyListNavController, chatNavController, nil];
        splitViewController.delegate = chatViewController;
        tabBarController.viewControllers = [NSArray arrayWithObjects:splitViewController, accountsNavController, nil];
        splitViewController.title = CHAT_STRING;
        splitViewController.tabBarItem.image = [UIImage imageNamed:@"08-chat.png"];
    }

    self.tabBarController = tabBarController;
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        NSLog(@"Notification Body: %@",localNotification.alertBody);
        NSLog(@"%@", localNotification.userInfo);
    }
    
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

/*- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"Notification Body: %@", notification.alertBody);
    NSLog(@"%@", notification.userInfo);
    
    application.applicationIconBadgeNumber = 0;
}*/

@end
