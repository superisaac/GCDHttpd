//
//  NSData+Base64.h
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-25.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (Utils)

- (NSData *)base64Decode;
- (NSData *)base64Encode;

- (NSInteger)firstPostionOfData:(NSData*)subData;
- (NSInteger)firstPostionOfData:(NSData *)subData offset:(NSInteger)offset;

@end
