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

@interface GCDFormPart : NSObject

@property (nonatomic, retain) NSMutableDictionary * headers;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * contentDisposition;

@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSString * fileName;
@property (nonatomic, retain) NSString * contentType;

- (BOOL)isFile;
@end

@interface GCDRequest : NSObject

@property (nonatomic, weak) GCDAsyncSocket * socket;
@property (nonatomic, retain) NSString * method;
@property (nonatomic, readonly) NSURL * requestURL;
@property (nonatomic, retain) NSString * pathString;
@property (nonatomic) NSInteger readedBodyLength;

@property (nonatomic, retain) NSMutableDictionary * META;
@property (nonatomic, readonly) NSDictionary * GET;
@property (nonatomic, retain) NSMutableDictionary * POST;
@property (nonatomic, retain) NSMutableDictionary * FILES;

@property (nonatomic, retain) NSData * rawData;
@property (nonatomic, retain) GCDFormPart * lastChunk;
@property (nonatomic, retain) NSDictionary * pathBindings;
@property (nonatomic, retain) GCDRouterRole * selectedRouterRole;

- (NSString *)multipartBoundaryWithPrefix:(NSString *)prefix;
- (BOOL)isMultipart;
- (void)setMetaVariable:(NSString *)value forKey:(NSString *)key;
@end
