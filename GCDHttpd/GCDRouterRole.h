//
//  GHHandler.h
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCDRequest;

@interface GCDRouterRole : NSObject

@property (nonatomic, retain) NSString * method;
@property (nonatomic, retain) NSString * pathPattern;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic, copy) id (^actionBlock)(GCDRequest * request);
@property (nonatomic, retain) id userData;

- (NSDictionary *)matchMethod:(NSString *)method path:(NSString *)path;

@end
