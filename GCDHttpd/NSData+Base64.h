//
//  NSData+Base64.h
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-25.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Base64)

- (NSData *)base64Decode;
- (NSData *)base64Encode;
@end
