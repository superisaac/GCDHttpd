//
//  ZKHTTPDService.h
//  GCDHttpdIOS
//
//  Created by stcui on 14-2-28.
//  Copyright (c) 2014年 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDHttpd.h"

@interface ZKHTTPDService : NSObject
@property (readonly, nonatomic) GCDHttpd *httpd;
@property (assign, nonatomic) int16_t httpdPort;
- (id)initWithPort:(uint16_t)port;
@end

@interface ZKHTTPDService (GCDHttpd)
- (void)start;
- (void)stop;
@end