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
    self.httpd.delegate = self;
    self.httpd.port = self.httpdPort;
    [self.httpd addTarget:self action:@selector(helloPage:) forMethod:@"GET" role:@"/hello"];
    [self.httpd addTarget:self action:@selector(deferredPage:) forMethod:@"GET" role:@"/deferred"];
    [self.httpd addTarget:self action:@selector(basicAuthPage:) forMethod:@"GET" role:@"/auth"];
    [self.httpd addTarget:self action:@selector(uploadPage:) forMethod:@"POST" role:@"/upload"];
    [self.httpd serveResource:@"index.html" forRole:@"/"];
    [self.httpd start];
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
- (id)helloPage:(GCDRequest*)request {
    return @"hello\n";
}

- (id)uploadPage:(GCDRequest *)request {
    GCDFormPart * part = request.FILES[@"ff"];
    if (part) {
        NSFileHandle * fileHandle = [NSFileHandle fileHandleForReadingAtPath:part.tmpFilename];
        NSData * fileData = [fileHandle readDataToEndOfFile];
        [fileHandle closeFile];
        NSLog(@"file content (%@)", [[NSString alloc ] initWithData:fileData encoding:NSUTF8StringEncoding]);
    }
    return @"ok\n";
}

- (id)basicAuthPage:(GCDRequest*)request {
    NSString * authUser = request.META[@"HTTP_AUTH_USER"];
    NSString * password = request.META[@"HTTP_AUTH_PW"];
    if (authUser == nil || password == nil || ![authUser isEqualToString:@"admin"] || ![password isEqualToString:@"123456"]) {
        GCDResponse * response = [GCDResponse responseWithStatus:401 message:@"Unauthorized"];
        response.headers[@"WWW-Authenticate"] = @"Basic realm=\"MyIphone\"";
        return response;
    } else {
        return @"You have successfully authorized to this device!\n";
    }
}


- (id)deferredPage:(GCDRequest*)request {
    GCDResponse * response = [GCDResponse responseChunked];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [response sendString:@"Deferred greeting after 2 seconds"];
        [response finish];
    });
    return response;
}

#pragma mark - GCDHttpdDelegate
- (id)willStartRequest:(GCDRequest *)request {
    // Do somthing to handle request
    NSLog(@"request %@", request.requestURL);
    return nil;
}

@end
