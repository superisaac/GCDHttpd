//
//  NSMutableData+Utils.m
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-3-3.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import "NSMutableData+Utils.h"

@implementation NSMutableData (Utils)

- (void)shiftDataFromIndex:(NSInteger)index {
    if (index < self.length) {
        Byte * buffer = [self mutableBytes];
        memmove(buffer, buffer + index, self.length - index);
        self.length = self.length - index;
    } else {
        self.length = 0;
    }
}

@end
