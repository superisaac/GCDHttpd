//
//  ZKWebViewController.m
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-25.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import "ZKWebViewController.h"

@interface ZKWebViewController ()

@end

@implementation ZKWebViewController
@synthesize webView, launchURL;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.launchURL) {
        NSURLRequest * request = [NSURLRequest requestWithURL:self.launchURL];
        NSLog(@"Load request %@", request);
        [self.webView loadRequest:request];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
