//
//  GHHandler.h
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDRouterRole : NSObject

@property (nonatomic, retain) NSString * method;
@property (nonatomic, retain) NSString * pathPattern;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic, retain) id userData;

- (NSDictionary *)matchMethod:(NSString *)method path:(NSString *)path;

@end
