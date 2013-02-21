GCDHttpd
========

GCDHttpd is a lightweight objective-c HTTP server framework build atop
[GCDAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket),
thus it is easy to be embeded in iOS/OSX projects.  The underline
grand central dispatch make the multi core programming easy.

## Install

Drag the Folder GCDHttpd into your Xcode projects

## Example Usage

```
    // Initialize the httpd
    httpd = [[GCDHttpd alloc] initWithDispatchQueue:dispatch_get_current_queue()];

    // Router setup
    // deferredIndex will be called on visiting "/users/jake"
    [httpd addTarget:self action:@selector(deferredIndex:) forMethod:@"GET" role:@"/users/:userid"];

    [httpd addTarget:self action:@selector(simpleIndex:) forMethod:@"GET" role:@"/"]; 

    [httpd serveDirectory:@"/tmp/" forURLPrefix:@"/t/"];    // Static file serving "/t/"
    [httpd serveResource:@"screen.png" forRole:@"/screen.png"];   // Resource in the main bundle
    [httpd listenOnInterface:nil port:8000];      // Listen on port 8000 of any interfaces
...

- (id)simpleIndex:(GCDRequest *)request {
    return @"hello";
}

- (id)deferredIndex:(GCDRequest*)request {
    NSString * message = [NSString stringWithFormat:@"hello %@", request.pathBindings[@"userid"]];
    GCDResponse * response = [GCDResponse responseWithContentLength:message.length];
    response.deferred = YES;
    
    // This request lasts 2 seconds
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
        [response sendString:message];
        [response finish];    // Finish the response
    });
    return response;
}

```


