//
//  GHHTTPParser.h
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "GCDRequest.h"
#import "GCDResponse.h"
#import "GCDRouterRole.h"

typedef NS_ENUM(NSInteger, GCDHttpdServerState)
{
    kHttpdStateInError = -1,
    kHttpdStateInitialized = 0,
    kHttpdStateStarted,
    kHttpdStateStopped
};

@protocol GCDHttpdDelegate <NSObject>
@optional
- (id) willStartRequest:(GCDRequest *)request;
- (void) didFinishedRequest:(GCDRequest *)request withResponse:(GCDResponse *)response;
@end

@interface GCDHttpd : NSObject <GCDAsyncSocketDelegate, GCDResponseDelegate, NSNetServiceDelegate>

@property (nonatomic) int16_t port;
@property (nonatomic, retain) NSString * interface;

@property (nonatomic) NSInteger maxBodyLength;
@property (nonatomic) int32_t maxAgeOfCacheControl;

@property (nonatomic, weak) id<GCDHttpdDelegate> delegate;
@property (nonatomic) GCDHttpdServerState httpdState;
@property (nonatomic, strong) NSNetService * netService;

+ (NSArray *)interfaceList;
- (id) initWithDispatchQueue:(dispatch_queue_t)queue;
- (void)start;
- (void)stop;

- (dispatch_queue_t)dispatchQueue;
- (GCDRouterRole *)addTarget:(id)target action:(SEL)action forMethod:(NSString *)method role:(NSString *)role;
- (GCDRouterRole *)addRouteforMethod:(NSString *)method role:(NSString *)role withAction:(id (^)(GCDRequest *))actionBlock;
- (void)serveDirectory:(NSString *)directory  forURLPrefix:(NSString *)prefix;
- (void)serveResource:(NSString *)resource forRole:(NSString *)resourceRole;

@end
