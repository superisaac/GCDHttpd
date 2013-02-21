//
//  GHHTTPParser.h
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "GCDResponse.h"
#import "GCDRouterRole.h"

@interface GCDHttpd : NSObject <GCDAsyncSocketDelegate, GCDResponseDelegate>

@property (nonatomic) NSInteger maxBodyLength;
@property (nonatomic) int32_t maxAgeOfCacheControl;

+ (NSArray *)addressList;
- (id) initWithDispatchQueue:(dispatch_queue_t)queue;
- (void)listenOnInterface:(NSString *)interface port:(NSInteger)port;

- (GCDRouterRole *)addTarget:(id)target action:(SEL)action forMethod:(NSString *)method role:(NSString *)role;
- (void)serveDirectory:(NSString *)directory  forURLPrefix:(NSString *)prefix;
- (void)serveResource:(NSString *)resource forRole:(NSString *)resourceRole;

@end
