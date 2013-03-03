//
//  GCDRequest.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import "GCDRequest.h"
#import "NSString+QueryString.h"

@implementation GCDRequest {
    NSString * _multipartBoundary;
    NSDictionary * _params;
}

@synthesize META, FILES, POST, pathBindings, pathString;
@synthesize method, selectedRouterRole, multipart;

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

@end
