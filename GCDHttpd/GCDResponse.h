//
//  GHResponse.h
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@class GCDResponse;
@protocol GCDResponseDelegate <NSObject>
- (void)response:(GCDResponse *)response hasData:(NSData *)data;
- (void)responseBeginSendData:(GCDResponse *)response;
- (void)responseWantToFinish:(GCDResponse *)response;
@end

@interface GCDResponse : NSObject

@property (nonatomic) NSInteger state;
@property (nonatomic) int32_t status;
@property (nonatomic, retain) NSMutableDictionary * headers;
@property (nonatomic) BOOL chunked;
@property (nonatomic) BOOL deferred;
@property (nonatomic, weak) id<GCDResponseDelegate> delegate;
@property (nonatomic, weak) GCDAsyncSocket * socket;

+ (NSString *) statusBrief:(int32_t)status;

- (id)initWithDelegate:(id<GCDResponseDelegate>)del socket:(GCDAsyncSocket *)sock;
- (void)sendData:(NSData *)data;
- (void)sendString:(NSString *)str;
- (void)finish;

@end
