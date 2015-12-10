//
//  ZKAddressListViewController.h
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-22.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZKHTTPDService.h"

@interface ZKAddressListViewController : UITableViewController
@property (assign, nonatomic) ZKHTTPDService *service;
- (id)initWithStyle:(UITableViewStyle)style service:(ZKHTTPDService *)service;
@end
