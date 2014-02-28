//
//  ZKAppDelegate.m
//  GCDHttpdOSX
//
//  Created by stcui on 14-2-28.
//  Copyright (c) 2014年 zengke. All rights reserved.
//

#import "ZKAppDelegate.h"
#import "GCDHttpd.h"
#import "ZKHTTPDService.h"

@implementation ZKAppDelegate
{
    ZKHTTPDService *_service;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _service = [[ZKHTTPDService alloc] initWithPort:3000];
    [_service start];
    NSArray *list = [GCDHttpd interfaceList];
    NSMutableArray *serviceList = [[NSMutableArray alloc] initWithCapacity:list.count];
    for (NSDictionary *item in list) {
        [serviceList addObject:@{@"addr":[item[@"address"] stringByAppendingFormat:@":%d", 3000]}];
    }
    [self.serviceArrayController setContent:serviceList];
}

- (void)loadURL:(NSString *)urlString
{
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[@"http://" stringByAppendingString: urlString]]];
    [self.webView.mainFrame loadRequest:req];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    [self loadURL:[self.serviceArrayController.arrangedObjects objectAtIndex:row][@"addr"]];
    return YES;
}

@end
