GCDHttpd
========

GCDHttpd is a lightweight objective-c HTTP server framework build atop GCDAsyncSocket, thus it is easy to be embeded in iOS/OSX projects.
The underline grand central dispatch make the multi core programming easy.

== Install ==

Drag the Folder GCDHttpd into your Xcode projects

== Example Usage ==

```
    httpd = [[GCDHttpd alloc] initWithDispatchQueue:dispatch_get_current_queue()];
    // Router setup
    [httpd addTarget:self action:@selector(deferredIndex:) forMethod:@"GET" role:@"/" ]; // self::deferredIndex will be called on visiting "/"
    [httpd serveDirectory:@"/tmp/" forURLPrefix:@"/t/"];    // Static file serving
    [httpd serveResource:@"screen.png" forRole:@"/screen.png"];   // Resource in the bundle
    [httpd listenOnInterface:nil port:8000];      // Listen on port 8000 of any interfaces
...

- (id)deferredIndex:(GCDRequest*)request {
    NSString * message = @"hello";
    GCDResponse * response = [GCDResponse responseWithContentLength:message.length];
    response.deferred = YES;
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
        [response sendString:message];
        [response finish];    // Close the response
    });
    return response;
}

```


