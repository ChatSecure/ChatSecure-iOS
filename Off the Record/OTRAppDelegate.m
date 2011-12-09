//
//  OTRAppDelegate.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRAppDelegate.h"

#import "OTRBuddyListViewController.h"
#import "OTRChatListViewController.h"
#import "OTRAccountsViewController.h"

@implementation OTRAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    OTRBuddyListViewController *viewController1 = [[OTRBuddyListViewController alloc] initWithNibName:@"OTRBuddyListViewController" bundle:nil];
    UIViewController *navController = [[UINavigationController alloc] initWithRootViewController:viewController1];
    OTRChatListViewController *viewController2 = [[OTRChatListViewController alloc] initWithNibName:@"OTRChatListViewController" bundle:nil];
    OTRAccountsViewController *viewController3 = [[OTRAccountsViewController alloc] init];
    UIViewController *navController3 = [[UINavigationController alloc] initWithRootViewController:viewController3];
    
    viewController2.buddyController = viewController1;
    viewController1.chatListController = viewController2;
    viewController1.tabController = _tabBarController;
    UIViewController *navController2 = [[UINavigationController alloc] initWithRootViewController:viewController2];
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController, navController2, navController3, nil];
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
