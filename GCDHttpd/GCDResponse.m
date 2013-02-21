//
//  GCDResponse.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import "GCDResponse.h"

@implementation GCDResponse {
    BOOL _finished;
}
@synthesize status, headers, chunked, delegate, socket, deferred;

+ (GCDResponse *)responseChunked {
    GCDResponse * response = [[GCDResponse alloc] init];
    response.chunked = YES;
    response.deferred = YES;
    [response.headers setObject:@"chunked" forKey:@"Transfer-Encoding"];
    return response;
}

+ (GCDResponse *)responseWithContentLength:(NSInteger)len {
    GCDResponse * response = [[GCDResponse alloc] init];
    if (len > 0) {
        [response.headers setObject:[NSString stringWithFormat:@"%ld", len] forKey:@"Content-Length"];
    }
    return response;
}

+ (GCDResponse*)responseWithStatus:(int32_t)status message:(NSString *)message {
    GCDResponse * response = [self responseWithContentLength:message.length];
    response.status = status;
    [response sendString:message];
    return response;
}

- (id)init {
    self = [super init];
    if (self) {
        _buffer = [[NSMutableData alloc] init];
        _finished = FALSE;
        self.status = 200;
        self.chunked = NO;
        self.deferred = NO;
        self.headers = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        @"text/html; charset=UTF-8", @"Content-Type",
                        @"GCDHttpd/0.1", @"Server",
                        nil];
    }
    return self;
}

- (NSString *) statusBrief {
    static NSDictionary * _statusBrief;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // TODO: Add more brief
        _statusBrief = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"OK", @"200",
                        @"Created", @"201",
                        @"Accepted", @"202",
                        
                        @"Moved Permanently", @"301",
                        @"Found", @"302",
                        @"See Other", @"303",
                        @"Not Modified", @"304",
                        
                        @"Bad Request", @"400",
                        @"Unauthorized", @"401",
                        @"Forbidden", @"403",
                        @"Not Found", @"404",
                        @"Method Not Allowed", @"405",
                        @"Request Entity Too Large", @"413",
                        
                        @"Internal Server Error", @"500",
                        nil];
    });
    return [_statusBrief objectForKey:[NSString stringWithFormat:@"%d", self.status]];
}

- (void)sendData:(NSData *)data {
    if (_finished) {
        NSLog(@"Already finished");
        return;
    }
    if (self.delegate) {
        [self sendBuffer];
        [self.delegate response:self didReceivedData:data];
    } else {
        [_buffer appendData:data];
    }
}

- (void)sendBuffer {
    if (_finished) {
        NSLog(@"Already finished");
        return;
    }
    if (_buffer.length > 0) {
        [self.delegate response:self didReceivedData:[NSData dataWithData:_buffer]];
        [_buffer setLength:0];
    }
}

- (void)sendString:(NSString *)str {
    [self sendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)finish {
    if (!_finished) {
        [self.delegate responseWantToFinish:self];
        _finished = YES;
    } else {
        NSLog(@"finish already called!");
    }
}

@end