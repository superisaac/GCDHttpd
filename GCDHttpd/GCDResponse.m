//
//  GCDResponse.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import "GCDResponse.h"

static const NSInteger kResponseStateInit = 0;
static const NSInteger kResponseStateSentHeaders = 1;
static const NSInteger kResponseStateFinished = 2;

@implementation GCDResponse {
    BOOL _finished;
}
@synthesize status, headers, chunked, delegate, socket, deferred;

- (id)initWithDelegate:(id<GCDResponseDelegate>)del socket:(GCDAsyncSocket *)sock {
    self = [super init];
    if (self) {
        self.delegate = del;
        self.socket = sock;
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

+ (NSString *) statusBrief:(int32_t)status {
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
    return [_statusBrief objectForKey:[NSString stringWithFormat:@"%d", status]];
}

- (void)sendData:(NSData *)data {
    if (_finished) {
        NSLog(@"Already finished");
        return;
    }
    
    if (self.state == kResponseStateInit) {
        [self.delegate responseBeginSendData:self];
        self.state = kResponseStateSentHeaders;
    }
    if (self.delegate) {
        [self.delegate response:self hasData:data];
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
