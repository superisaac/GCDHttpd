//
//  ZKAddressListViewController.m
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-22.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import "ZKAddressListViewController.h"
#import "ZKWebViewController.h"
#import "GCDHttpd.h"
#import "ZKAppDelegate.h"

@interface ZKAddressListViewController () {
    NSArray * _addressList;
}

@end

@implementation ZKAddressListViewController

- (id)initWithStyle:(UITableViewStyle)style service:(ZKHTTPDService *)service
{
    self = [super initWithStyle:style];
    if (self) {
        _service = service;
        _addressList = [[NSArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _addressList = [GCDHttpd interfaceList];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _addressList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[CellIdentifier]; // forIndexPath:indexPath];
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    NSDictionary * info = [_addressList objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"http://%@:%d/", [info objectForKey:@"address"], self.service.httpdPort];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    ZKWebViewController * viewController = [[ZKWebViewController alloc] initWithNibName:@"ZKWebViewController" bundle:nil];
    viewController.title = cell.textLabel.text;
    viewController.launchURL = [NSURL URLWithString:cell.textLabel.text];

    [self.navigationController pushViewController:viewController animated:YES];
}


@end
