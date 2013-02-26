//
//  ZKWebViewController.h
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-25.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZKWebViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIWebView * webView;
@property (nonatomic, retain) NSURL * launchURL;
@end
