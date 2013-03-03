//
//  NSData+Base64.m
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-2-25.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import "NSData+Utils.h"

static unsigned char base64EncodeLookup[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation NSData (Utils)

- (NSData *)base64Encode {
    NSInteger outputCapacity = (NSInteger)ceil(self.length * 4.0 / 3);
    NSMutableData * output = [NSMutableData dataWithCapacity:outputCapacity];
    [output setLength:outputCapacity];
    Byte * inputBuffer = (Byte *)[self bytes];
    Byte * outputBuffer = (Byte *)[output mutableBytes];
    NSInteger i = 0;
    NSInteger j = 0;
    NSInteger shiftLength = (NSInteger)floor(self.length/3) * 3;
    
    while(i < shiftLength) {
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
        outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4) | ((inputBuffer[i + 1] & 0xF0) >> 4)];
        outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2) | ((inputBuffer[i + 2] & 0xC0) >> 6)];        
        outputBuffer[j++] = base64EncodeLookup[inputBuffer[i + 2] & 0x3F];
        i += 3;
    }
    NSInteger n = self.length - shiftLength;
    if (n == 1) {
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0x03) << 4];
        outputBuffer[j++] = '=';
        outputBuffer[j++] = '=';
    } else if (n == 2) {
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
        outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4) | ((inputBuffer[i + 1] & 0xF0) >> 4)];
        outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2)];
        outputBuffer[j++] = '=';
    } else {
        assert(n == 0);
    }
    
    NSAssert(outputCapacity >= j, @"");
    [output setLength:j];
    return output;
}

static unsigned char _base64DecodeLookup(unsigned char b) {
    unsigned char r ;
    if(b >= 'A' && b <= 'Z') {
        r = (b - 'A');
    } else if(b >= 'a' && b <= 'z') {
        r = (b - 'a' + 26);
    } else if(b >= '0' && b <= '9') {
        r = (b - '0' + 52);
    } else if(b == '+') {
        r = 62;
    } else if(b == '/') {
        r = 63;
    } else {
        assert(FALSE);
    }
    return r;
}

- (NSData *)base64Decode {
    NSInteger inputLength = self.length;
    NSAssert(inputLength % 4 == 0, @"Must be aligned with word boundary");
    NSInteger outputCapacity = (NSInteger)(3 * inputLength) >> 2;
    NSMutableData * output = [NSMutableData dataWithCapacity:outputCapacity];
    [output setLength:outputCapacity];
    
    
    unsigned char * inputBuffer = (unsigned char *)[self bytes];
    unsigned char * outputBuffer = (unsigned char *)[output mutableBytes];
    
    NSInteger i = 0;
    NSInteger j = 0;
    while (i < inputLength) {
        outputBuffer[j++] = (_base64DecodeLookup(inputBuffer[i]) << 2) | (_base64DecodeLookup(inputBuffer[i+1]) >> 4);
        
        if (inputBuffer[i + 2] == '=') {
            break;
        }
        outputBuffer[j++] = (_base64DecodeLookup(inputBuffer[i+1]) << 4) | (_base64DecodeLookup(inputBuffer[i+2]) >> 2);
        
        if (inputBuffer[i + 3] == '=') {
            break;
        }
        outputBuffer[j++] = (_base64DecodeLookup(inputBuffer[i+2]) << 6) | _base64DecodeLookup(inputBuffer[i+3]);
        i += 4;
    }
    [output setLength:j];
    return output;
}

- (NSInteger)firstPostionOfData:(NSData*)subData {
    return [self firstPostionOfData:subData offset:0];
}

- (NSInteger)firstPostionOfData:(NSData *)subData offset:(NSInteger)offset {
    NSAssert(subData.length > 0, @"Empty sub");
    NSInteger subLength = subData.length;
    NSInteger availLength = self.length - subLength;
    if (availLength < offset) {
        return -1;
    }
    
    Byte * selfBytes = (Byte*)[self bytes];
    Byte * subBytes = (Byte *)[subData bytes];
    for (NSInteger i=offset; i< availLength; i++) {
        if(0 == memcmp(selfBytes + i, subBytes, subLength)) {
            // Found
            return i;
        }
    }
    return -1;
}

@end
