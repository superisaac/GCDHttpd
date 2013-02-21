//
//  NSURL+IntacePath.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-2-21.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import "NSURL+IntactPath.h"

@implementation NSURL (IntactPath)

- (NSString *)intactPath {
    Boolean isAbsolute = YES;
    // The only way to get path reserving the trailing slash
    NSString * path = self.path;
    if (![path isEqual: @"/"]) {
        path = (NSString *)CFBridgingRelease(CFURLCopyStrictPath((__bridge_retained CFURLRef)(self), &isAbsolute));
    }
    if (path.length > 0 && ![[path substringToIndex:1] isEqualToString:@"/"]) {
        path = [NSString stringWithFormat:@"/%@", path];
    }
    return path;
}
@end
