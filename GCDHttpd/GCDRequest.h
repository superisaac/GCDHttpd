//
//  GHRequest.h
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "GCDRouterRole.h"
#import "GCDMultipart.h"

@class GCDHttpd;
@class GCDResponse;

@interface GCDRequest : NSObject

@property (nonatomic, weak) GCDAsyncSocket * socket;
@property (nonatomic, weak) GCDHttpd * httpd;
@property (nonatomic, retain) NSString * method;
@property (nonatomic, readonly) NSURL * requestURL;
@property (nonatomic, retain) NSString * pathString;
@property (nonatomic) NSInteger readedBodyLength;

@property (nonatomic, retain) NSMutableDictionary * META;
@property (nonatomic, readonly) NSDictionary * GET;
@property (nonatomic, retain) NSMutableDictionary * POST;
@property (nonatomic, retain) NSMutableDictionary * FILES;

@property (nonatomic, retain) NSData * rawData;
@property (nonatomic, retain) GCDMultipart * multipart;
@property (nonatomic, retain) NSDictionary * pathBindings;
@property (nonatomic, retain) GCDRouterRole * selectedRouterRole;

- (GCDResponse *)responseChunked;
- (GCDResponse *)responseWithContentLength:(NSInteger)len;
- (GCDResponse *)responseWithStatus:(int32_t)status message:(NSString *)message;
- (GCDResponse*)responseWithStatus:(int32_t)status;

- (NSString *)multipartBoundaryWithPrefix:(NSString *)prefix;
- (BOOL)isMultipart;
- (void)setMetaVariable:(NSString *)value forKey:(NSString *)key;

@end
