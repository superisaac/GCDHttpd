//
//  ZKAppDelegate.m
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-22.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import "ZKAppDelegate.h"

#import "ZKAddressListViewController.h"

@implementation ZKAppDelegate
@synthesize httpd, httpdPort;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.httpdPort = 3000;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    UINavigationController * navController = [[UINavigationController alloc] initWithNibName:nil bundle:nil];
    ZKAddressListViewController * viewController = [[ZKAddressListViewController alloc] initWithStyle:UITableViewStylePlain];
    viewController.title = @"GCDHttpd Demo";
    [navController setViewControllers:[NSArray arrayWithObject:viewController]];
    self.viewController = navController;
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    // Initialize the httpd
    self.httpd = [[GCDHttpd alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    [self.httpd addTarget:self action:@selector(indexPage:) forMethod:@"GET" role:@"/hello"];
    [self.httpd serveResource:@"index.html" forRole:@"/"];
    [self.httpd listenOnInterface:nil port:self.httpdPort];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - web functions
- (id)indexPage:(GCDRequest*)request {
    return @"hello";
}

@end
