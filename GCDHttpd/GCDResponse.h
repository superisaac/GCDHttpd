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
- (void)response:(GCDResponse *)response didReceivedData:(NSData *)data;
- (void)responseWantToFinish:(GCDResponse *)response;
@end

@interface GCDResponse : NSObject

@property (nonatomic) int32_t status;
@property (nonatomic, retain) NSMutableDictionary * headers;
@property (nonatomic, readonly) NSMutableData * buffer;
@property (nonatomic) BOOL chunked;
@property (nonatomic) BOOL deferred;
@property (nonatomic, weak) id<GCDResponseDelegate> delegate;
@property (nonatomic, retain) GCDAsyncSocket * socket;

+ (GCDResponse *)responseChunked;
+ (GCDResponse *)responseWithContentLength:(NSInteger)len;
+ (GCDResponse *)responseWithStatus:(int32_t)status message:(NSString *)message;
+ (GCDResponse*)responseWithStatus:(int32_t)status;
+ (NSString *) statusBrief:(int32_t)status;

- (void)sendBuffer;
- (void)sendData:(NSData *)data;
- (void)sendString:(NSString *)str;
- (void)finish;

@end
