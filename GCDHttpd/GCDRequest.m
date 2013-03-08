//
//  GCDRequest.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import "GCDRequest.h"
#import "GCDResponse.h"

#import "NSString+QueryString.h"
#import "GCDHttpd.h"

@implementation GCDRequest {
    NSString * _multipartBoundary;
    NSDictionary * _params;
}

@synthesize META, FILES, POST, pathBindings, pathString;
@synthesize method, selectedRouterRole, multipart, httpd;

- (id)init {
    self = [super init];
    if (self) {
        // Initialize
        self.META = [[NSMutableDictionary alloc] init];
        self.POST = [[NSMutableDictionary alloc] init];
        self.FILES = [[NSMutableDictionary alloc] init];
        self.readedBodyLength = 0;
    }
    return self;
}

- (NSDictionary *)GET {
    if (_params == nil) {
        _params = [self.requestURL.query explodeToQueryDictionary];
    }
    return _params;
}

- (NSURL *)requestURL {
    NSString * host = self.META[@"HTTP_HOST"];
    if (host == nil) {
        host = @"";
    }
    NSString * absoluteURLString = [NSString stringWithFormat:@"http://%@%@", host, self.pathString];
    return [NSURL URLWithString:absoluteURLString];
}

- (BOOL)isMultipart {
    NSString * contentType = self.META[@"CONTENT_TYPE"];
    return (contentType != nil && [[contentType substringToIndex:10] isEqualToString:@"multipart/"]);
}

- (NSString *)multipartBoundaryWithPrefix:(NSString *)prefix {
    NSAssert([self isMultipart], @"Content-Type is not multipart");
    if (_multipartBoundary != nil) {
        return [NSString stringWithFormat:@"%@%@", prefix, _multipartBoundary];
    }
    
    NSString * contentType = self.META[@"CONTENT_TYPE"];
    NSError * error;
    NSRegularExpression * boundaryFinder = [NSRegularExpression regularExpressionWithPattern:@"boundary=(\")?([^\"]*)(\")?" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    if (error != nil) {
        NSLog(@"Error on boundary finder exp %@", [error description]);
        return nil;
    }
    NSTextCheckingResult * match = [boundaryFinder firstMatchInString:contentType options:0 range:NSMakeRange(0, contentType.length)];
    if (match != nil) {
        NSRange range = [match rangeAtIndex:2];
        _multipartBoundary = [contentType substringWithRange:range];
        return [NSString stringWithFormat:@"%@%@", prefix, _multipartBoundary];
    }
    return nil;
}

+ (NSSet *) builtinVarNames {
    static NSSet * _varNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _varNames = [[NSSet alloc] initWithObjects:@"AUTH_TYPE", @"CONTENT_LENGTH", @"REMOTE_ADDR", @"CONTENT_TYPE",
                        @"QUERY_STRING", nil];
    });
    return _varNames;
}
- (void)setMetaVariable:(NSString *)value forKey:(NSString *)key {
    if (value == nil) {
        value = @"";
    }
    // Refer to http://www.ietf.org/rfc/rfc3875 Request Meta-Variables
    key = [key stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    key = [key uppercaseString];
    NSString * scheme = @"HTTP";
    if (![[[self class] builtinVarNames] containsObject:key]) {
        key = [NSString stringWithFormat:@"%@_%@", scheme, key];
    }
    self.META[key] = value;
}

// Generate response
- (GCDResponse *)responseChunked {
    GCDResponse * response = [[GCDResponse alloc] initWithDelegate:self.httpd socket:self.socket];
    response.chunked = YES;
    response.deferred = YES;
    [response.headers setObject:@"chunked" forKey:@"Transfer-Encoding"];
    return response;
}

- (GCDResponse *)responseWithContentLength:(NSInteger)len {
    GCDResponse * response = [[GCDResponse alloc] initWithDelegate:self.httpd socket:self.socket];
    if (len > 0) {
        [response.headers setObject:[NSString stringWithFormat:@"%d", len] forKey:@"Content-Length"];
    }
    return response;
}

- (GCDResponse*)responseWithStatus:(int32_t)status message:(NSString *)message {
    GCDResponse * response = [self responseWithContentLength:message.length];
    response.status = status;
    response.deferred = YES;
    dispatch_async(self.httpd.dispatchQueue, ^{
        [response sendString:message];
        [response finish];
    });
    return response;
}

- (GCDResponse*)responseWithStatus:(int32_t)status {
    NSString * message = [GCDResponse statusBrief:status];
    return [self responseWithStatus:status message:message];
}
@end
