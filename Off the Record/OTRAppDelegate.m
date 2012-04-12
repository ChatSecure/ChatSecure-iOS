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

#ifdef CRITTERCISM_ENABLED
#import "Crittercism.h"
#import "OTRCrittercismSecrets.h"
#endif

@implementation OTRAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef CRITTERCISM_ENABLED
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults boolForKey:CRITTERCISM_OPT_IN])
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
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
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

@end
