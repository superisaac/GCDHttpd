//
//  ZKHTTPDService.m
//  GCDHttpdIOS
//
//  Created by stcui on 14-2-28.
//  Copyright (c) 2014年 zengke. All rights reserved.
//

#import "ZKHTTPDService.h"

#if TARGET_OS_IPHONE
typedef UIImage ZKImage;
#else
typedef NSImage ZKImage;
#endif

@interface ZKHTTPDService () <GCDHttpdDelegate>
@property (strong, nonatomic) GCDHttpd *httpd;
@end

@implementation ZKHTTPDService
- (id)initWithPort:(uint16_t)port
{
    self = [super init];
    if (self) {
        // Initialize the httpd
        self.httpd = [[GCDHttpd alloc] initWithDispatchQueue:dispatch_get_main_queue()];
        self.httpd.delegate = self;
        self.httpdPort = port;
        self.httpd.port = self.httpdPort;
        [self.httpd serveDirectory:NSTemporaryDirectory() forURLPrefix:@"/tmp/"];
        [self.httpd addTarget:self action:@selector(helloPage:) forMethod:@"GET" role:@"/hello"];
        [self.httpd addTarget:self action:@selector(deferredPage:) forMethod:@"GET" role:@"/deferred"];
        [self.httpd addTarget:self action:@selector(basicAuthPage:) forMethod:@"GET" role:@"/auth"];
        [self.httpd addTarget:self action:@selector(uploadPage:) forMethod:@"POST" role:@"/upload"];
        [self.httpd serveResource:@"index.html" forRole:@"/"];
    }
    return self;
}

#pragma mark - web functions
- (id)helloPage:(GCDRequest*)request {
    return @"hello\n";
}

- (id)uploadPage:(GCDRequest *)request {
    GCDFormPart * part = request.FILES[@"ff"];
    if (part) {
        ZKImage * image = [[ZKImage alloc] initWithContentsOfFile:part.tmpFilename];
#if TARGET_OS_IPHONE
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        NSData * imageData = UIImageJPEGRepresentation(image, 0.9);
#else
        NSBitmapImageRep *imgRep = [[image representations] objectAtIndex: 0];
        NSData *imageData = [imgRep representationUsingType: NSPNGFileType properties: nil];
#endif
        NSString * destImageFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"uploaded.jpg"];
        [imageData writeToFile:destImageFilename atomically:NO];
        
        GCDResponse * response = [request responseWithStatus:302];
        response.headers[@"Location"] = @"/tmp/uploaded.jpg";
        return response;
    }
    return @"ok\n";
}

- (id)basicAuthPage:(GCDRequest*)request {
    NSString * authUser = request.META[@"HTTP_AUTH_USER"];
    NSString * password = request.META[@"HTTP_AUTH_PW"];
    
    if (authUser == nil || password == nil || ![authUser isEqualToString:@"admin"] || ![password isEqualToString:@"123456"]) {
        GCDResponse * response = [request responseWithStatus:401 message:@"Unauthorized"];
        response.headers[@"WWW-Authenticate"] = @"Basic realm=\"MyIphone\"";
        return response;
    } else {
        return @"You have successfully authorized to this device!\n";
    }
}


- (id)deferredPage:(GCDRequest*)request {
    GCDResponse * response = [request responseChunked];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [response sendString:@"Deferred greeting after 2 seconds"];
        [response finish];
    });
    return response;
}


#pragma mark - GCDHttpdDelegate
- (id)willStartRequest:(GCDRequest *)request {
    // Do somthing to handle request
    NSLog(@"request %@", request.requestURL);
    return nil;
}

// Save image
-(void)image:(ZKImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        /*   UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save photo eror", nil) message:[error description] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
         [alertView show]; */
        NSLog(@"save image failed!");
    }
    NSLog(@"image saved %@", contextInfo);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
    if (!sig) {
        sig = [self.httpd methodSignatureForSelector:aSelector];
    }
    return sig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([self.httpd respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.httpd];
    }
}

@end
