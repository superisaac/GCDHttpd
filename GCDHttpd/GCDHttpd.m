//
//  GCDHttpd.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "GCDHttpd.h"
#import "GCDRequest.h"

#import "NSString+QueryString.h"
#import "NSURL+IntactPath.h"

static const long kTagWriteAndClose = 1000;

static const long kTagReadStatusLine = 1101;
static const long kTagReadHeaderLine = 1102;

static const long kTagReadPostContentLength = 1103;
static const long kTagReadMultipartBoundary = 1104;
static const long kTagReadMultipartEndTest = 1105;
static const long kTagReadMultipartHeader = 1106;


@implementation GCDHttpd {
    GCDAsyncSocket * _listenSocket;
    NSMutableArray * _roles;
    dispatch_queue_t _dispatchQueue;
}

+ (NSArray *)addressList {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                NSString * interface = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString * address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                NSDictionary * addrInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                           interface, @"interface",
                                           address, @"address",
                                           nil];
                [arr addObject:addrInfo];
                
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return arr;    
}

- (id) initWithDispatchQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _dispatchQueue = queue;
        _roles = [[NSMutableArray alloc] init];
        self.maxBodyLength = 4 * 1024 * 1024; // 4M bytes
        self.maxAgeOfCacheControl = 2; // 2 seconds
    }
    return self;
}

- (void)listenOnInterface:(NSString *)interface port:(NSInteger)port {
    _listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_dispatchQueue];
    NSError * error = nil;
    if (![_listenSocket acceptOnInterface:interface port:port error:&error]) {
        NSLog(@"Error on listen %@", [error description]);
    }
}

- (void)socket:(GCDAsyncSocket*)sock readLineWithTag:(long)tag {
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    GCDRequest * request = [[GCDRequest alloc] init];
    request.socket = newSocket;
    newSocket.userData = request;
    [self socket:newSocket readLineWithTag:kTagReadStatusLine];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == kTagWriteAndClose) {
        [sock disconnect];
    }
}

/**
 * The big state machine to handle HTTP Request and Response
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    GCDRequest * request = (GCDRequest *)(sock.userData);
    if (tag > kTagReadHeaderLine) {
        request.readedBodyLength += data.length;
        if (request.readedBodyLength > self.maxBodyLength) {
            [self socket:sock httpErrorStatus:413 message:@"Entity Too Large\n"];
            return;
        }
    }
    if (tag == kTagReadStatusLine) {
        NSString * line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray * parts = [line componentsSeparatedByString:@" "];
        assert(parts.count == 3);
        request.method = [parts objectAtIndex:0];
        request.pathString = [parts objectAtIndex:1];
        [self socket:sock readLineWithTag:kTagReadHeaderLine];
    } else if (tag == kTagReadHeaderLine) {
        if (data.length > 2) {
            NSString * line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSRange range = [line rangeOfString:@":"];
            NSString * key = [line substringToIndex:range.location];
            NSString * value = [[line substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [request setMetaVariable:value forKey:key];
            [self socket:sock readLineWithTag:kTagReadHeaderLine];
        } else {
            // Empty lines
            [request setMetaVariable:request.requestURL.query forKey:@"QUERY_STRING"];
            
            NSInteger contentLength = [request.META[@"CONTENT_LENGTH"] intValue];
            if (contentLength > 0 && contentLength > self.maxBodyLength) {
                [self socket:sock httpErrorStatus:413 message:@"Entity Too Large\n"];
                return; 
            }
            
            if ([request.method isEqualToString:@"GET"]) {
                [self socket:sock endParsingRequest:request];
            } else if([request.method isEqualToString:@"POST"]) {
                if ([request isMultipart]){
                    NSString * boundary = [request multipartBoundaryWithPrefix:@"--"];
                    NSAssert(boundary != nil, @"boundary is nil");
                    [sock readDataToData:[boundary dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 maxLength:(self.maxBodyLength - request.readedBodyLength) tag:kTagReadMultipartBoundary];
                    return;
                }
                
                if (contentLength > 0) {
                    [sock readDataToLength:contentLength withTimeout:-1 tag:kTagReadPostContentLength];
                }
            }
        }
    } else if (tag == kTagReadPostContentLength) {
        request.rawData = data;
        NSString * contentType = request.META[@"CONTENT_TYPE"];
        if ([contentType isEqualToString:@"application/x-www-form-urlencoded"]) {
             NSString * postBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [request.POST setValuesForKeysWithDictionary:[postBody explodeToQueryDictionary]];
        } else if ([request isMultipart]){
            NSString * boundary = [request multipartBoundaryWithPrefix:@"--"];
            NSAssert(boundary != nil, @"boundary is nil");
            [sock readDataToData:[boundary dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:kTagReadMultipartBoundary];
            return;
        }
        [self socket:sock endParsingRequest:request];
    } else if (tag == kTagReadMultipartBoundary) {
        GCDMultipartChunk * chunk = request.lastChunk;
        if (chunk) {
            NSString * boundary = [request multipartBoundaryWithPrefix:@"--"];
            chunk.data = [data subdataWithRange:NSMakeRange(0, data.length - boundary.length - 2)];
            if (chunk.isFile) {
                // A file is uploaded, store it into request.FILES
                [request.FILES setObject:chunk forKey:chunk.name];
            } else {
                // An variable
                NSString * strValue = [[NSString alloc] initWithData:chunk.data encoding:NSUTF8StringEncoding];
                [request.POST setObject:strValue forKey:chunk.name];
            }
        }
        [sock readDataToLength:2 withTimeout:-1 tag:kTagReadMultipartEndTest];
    } else if (tag == kTagReadMultipartEndTest) {
        if([data isEqualToData:[GCDAsyncSocket CRLFData]]) {
            request.lastChunk = [[GCDMultipartChunk alloc] init];
            [self socket:sock readLineWithTag:kTagReadMultipartHeader];
        } else {
            NSAssert([data isEqualToData:[@"--" dataUsingEncoding:NSUTF8StringEncoding]], @"Unexpected chars beyond CRLF and --");
            [self socket:sock endParsingRequest:request];
        }
    } else if (tag == kTagReadMultipartHeader) {
        if (data.length > 2) {
            GCDMultipartChunk * chunk = request.lastChunk;
            NSAssert(chunk != nil, @"Chunk is null");
            
            NSString * line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSRange range = [line rangeOfString:@":"];
            NSString * key = [line substringToIndex:range.location];
            key = [key lowercaseString];
            NSString * value = [[line substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([key isEqualToString:@"content-disposition"]) {
                chunk.contentDisposition = value;
            } else if ([key isEqualToString:@"content-type"]) {
                chunk.contentType = value;
            } else {
                [chunk.headers setObject:value forKey:key];
            }
            [self socket:sock readLineWithTag:kTagReadMultipartHeader];
        } else {
            // Empty line means multipart chunk headers are parsed
            // 
            NSString * boundary = [request multipartBoundaryWithPrefix:@"--"];
            NSAssert(boundary != nil, @"boundary is nil");
            [sock readDataToData:[boundary dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 maxLength:(self.maxBodyLength - request.readedBodyLength) tag:kTagReadMultipartBoundary];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock endParsingRequest:(GCDRequest *)request {
    request.lastChunk = nil;
    NSString * path = request.requestURL.intactPath;
    for (GCDRouterRole * roleEntry in _roles) {
        NSDictionary * bindings = [roleEntry matchMethod:request.method path:path];
        if (bindings != nil) {
            request.pathBindings = bindings;
            request.selectedRouterRole = roleEntry;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id response = [roleEntry.target performSelector:roleEntry.action withObject:request];
#pragma clang diagnostic pop
            [self socket:sock generateResponse:response];
            return;
        }
    }
    [self socket:sock httpErrorStatus:404 message:@"Object Not Found\n"];
}


- (void)socket:(GCDAsyncSocket * )sock writeString:(NSString *)str tag:(long)tag {
    [sock writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:tag];
}

- (void)socket:(GCDAsyncSocket * )sock writeString:(NSString *)str {
    [self socket:sock writeString:str tag:0];
}


- (void)socket:(GCDAsyncSocket *)sock generateResponse:(id)response {
    GCDResponse * resp;
    NSData * payload = nil;
    if ([response isKindOfClass:[NSString class]]) {
        payload = [(NSString *)response dataUsingEncoding:NSUTF8StringEncoding];
        resp = [GCDResponse responseWithContentLength:payload.length];
    } else if ([response isKindOfClass:[NSData class]]){
        payload = (NSData*)response;
        resp = [GCDResponse responseWithContentLength:payload.length];
    } else {
        assert([response isKindOfClass:[GCDResponse class]]);
        resp = (GCDResponse *)response;
    }
    resp.delegate = self;
    resp.socket = sock;
    
    // Output headers
    NSString * statusLine = [NSString stringWithFormat:@"HTTP/1.1 %d %@\r\n", resp.status, resp.statusBrief];
    [self socket:sock writeString:statusLine];

    for(NSString * key in resp.headers) {
        NSString * value = [resp.headers objectForKey:key];
        NSString * headerLine = [NSString stringWithFormat:@"%@: %@\r\n", key, value];
        [self socket:sock writeString:headerLine];
    }
    [self socket:sock writeString:@"\r\n"];
    
    // If there is payload, just send them
    if (payload) {
        [resp sendData:payload];
        [resp finish];
    } else if (resp.buffer.length > 0){
        [resp sendBuffer];
        if (!resp.deferred) {
            [resp finish];
        }
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socket closed %@", err);
}

# pragma mark - GHResponseDelegate
- (void)responseWantToFinish:(GCDResponse *)response {
    if (response.chunked) {
        NSData * zero = [@"0\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
        [response.socket writeData:zero withTimeout:-1 tag:kTagWriteAndClose];
    } else {
        [response.socket writeData:[GCDAsyncSocket ZeroData] withTimeout:-1 tag:kTagWriteAndClose];
    }
}

- (void)response:(GCDResponse *)response didReceivedData:(NSData *)data {
    if (response.chunked) {
        NSMutableData * buffer = [[NSMutableData alloc] init];
        NSString * cntData = [NSString stringWithFormat:@"%X\r\n", data.length];
        NSData * cnt = [cntData dataUsingEncoding:NSUTF8StringEncoding];
        [buffer appendData:cnt];
        [buffer appendData:data];
        [buffer appendData:[GCDAsyncSocket CRLFData]];
        [response.socket writeData:buffer withTimeout:-1 tag:0];
    } else {
        [response.socket writeData:data withTimeout:-1 tag:0];
    }
}

- (GCDRouterRole *)addTarget:(id)target action:(SEL)action forMethod:(NSString *)method role:(NSString *)role  {
    GCDRouterRole * roleEntry = [[GCDRouterRole alloc] init];
    roleEntry.target = target;
    roleEntry.action = action;
    roleEntry.method = method;
    roleEntry.pathPattern = role;
    [_roles addObject:roleEntry];
    return roleEntry;
}

+ (NSString * )contentTypeForExtension:(NSString * )extension {
    static NSDictionary * typeMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeMap = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"text/html", @"html",
                   @"text/html", @"htm",
                   @"text/plain", @"txt",
                   @"text/javascript", @"js",
                   @"text/css", @"css",
                   @"image/jpeg", @"jpg",
                   @"image/jpeg", @"jpeg",
                   @"image/gif", @"gif",
                   @"image/png", @"png",
                   @"audio/mp3", @"mp3",
                   @"audio/aac", @"aac",
                   @"video/mov", @"mov",
                   @"video/avi", @"avi",
                   @"application/json", @"json",
                   nil];
    });
    NSString * type = typeMap[[extension lowercaseString]];
    if (type == nil) {
        return @"application/octet-stream";
    }
    return type;
}

#pragma mark - static file hosting
- (void)serveDirectory:(NSString *)directory  forURLPrefix:(NSString *)prefix {
    NSString * staticRole = [NSString stringWithFormat:@"%@::path", prefix];
    GCDRouterRole * role = [self addTarget:self action:@selector(serveStaticFile:) forMethod:@"GET" role:staticRole];
    role.userData = directory;
}


- (id) serveStaticFile:(GCDRequest *)request {
    NSString * relativePath = request.pathBindings[@"path"];
    if (relativePath == nil || relativePath.length == 0) {
        relativePath = @"/";
    }
    if ([[relativePath substringFromIndex:relativePath.length-1] isEqualToString:@"/"]) {
        relativePath = [NSString stringWithFormat:@"%@index.html", relativePath];
    }
    NSString * directory = request.selectedRouterRole.userData;
    NSMutableArray * arr =  [NSMutableArray arrayWithArray:[directory componentsSeparatedByString:@"/"]];
    [arr addObjectsFromArray:[relativePath componentsSeparatedByString:@"/"]];
    NSString * absPath = [arr componentsJoinedByString:@"/"];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:absPath]) {
        return [GCDResponse responseWithStatus:404 message:@"Object Not Found"];
    }

    NSData * data = [NSData dataWithContentsOfFile:absPath];
    GCDResponse * response = [GCDResponse responseWithContentLength:data.length];
    [response.headers setObject:[NSString stringWithFormat:@"max-age=%d", self.maxAgeOfCacheControl] forKey:@"Cache-Control"];
    [response.headers setObject:[[self class] contentTypeForExtension:[absPath pathExtension]] forKey:@"Content-Type"];
    [response sendData:data];
    return response;
}

#pragma mark - resource in an bundle
- (void)serveResource:(NSString *)resource forRole:(NSString *)resourceRole {
    GCDRouterRole * role = [self addTarget:self action:@selector(serveResource:) forMethod:@"GET" role:resourceRole];
    role.userData = resource;
}

- (id)serveResource:(GCDRequest * )request {
    NSBundle * bundle = [NSBundle mainBundle];
    NSString * resource = request.selectedRouterRole.userData;
    NSURL * url = [bundle URLForResource:resource withExtension:nil];
    if (url == nil) {
        return [GCDResponse responseWithStatus:404 message:@"Resource cannot be located\n"];
    }
    NSData * data = [NSData dataWithContentsOfURL:url];
    GCDResponse * response = [GCDResponse responseWithContentLength:data.length];
    [response.headers setObject:[NSString stringWithFormat:@"max-age=%d", self.maxAgeOfCacheControl] forKey:@"Cache-Control"];
    [response.headers setObject:[[self class] contentTypeForExtension:[resource pathExtension]] forKey:@"Content-Type"];
    [response sendData:data];
    return response;
}

// Handlers
// error response
- (void)socket:(GCDAsyncSocket *)sock httpErrorStatus:(int32_t)status message:(NSString *)message {
    GCDResponse * response = [GCDResponse responseWithStatus:status message:message];
    [self socket:sock generateResponse:response];
}

@end
