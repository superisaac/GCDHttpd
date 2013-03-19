//
//  GCDMultipart.h
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-3-3.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDFormPart : NSObject

@property (nonatomic, retain) NSMutableDictionary * headers;
@property (nonatomic, retain) NSMutableData * data;
@property (nonatomic, retain) NSString * contentDisposition;

@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSString * fileName;
@property (nonatomic, retain) NSString * contentType;
@property (nonatomic, retain) NSString * tmpFilename;

- (BOOL)isFile;
- (void)close;
@end

@interface GCDMultipart : NSObject

@property (nonatomic) BOOL finished;
@property (nonatomic, retain) NSMutableDictionary * POST;
@property (nonatomic, retain) NSMutableDictionary * FILES;

- (id)initWithBundary:(NSString*)boundary;
- (void)feed:(NSData*)data error:(NSError * __autoreleasing *)error;

@end
