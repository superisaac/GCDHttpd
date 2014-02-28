//
//  ZKAppDelegate.h
//  GCDHttpdOSX
//
//  Created by stcui on 14-2-28.
//  Copyright (c) 2014年 zengke. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ZKAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSArrayController *serviceArrayController;
@property (assign) IBOutlet WebView *webView;
@end
