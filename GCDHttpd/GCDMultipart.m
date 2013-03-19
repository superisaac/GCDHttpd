//
//  GCDMultipart.m
//  GCDHttpdIOS
//
//  Created by 曾科 on 13-3-3.
//  Copyright (c) 2013年 zengke. All rights reserved.
//

#import "GCDMultipart.h"
#import "NSData+Utils.h"
#import "NSMutableData+Utils.h"
#import "GCDAsyncSocket.h"

// Constants
const NSInteger kWatchTypeData = 100;
const NSInteger kWatchTypeLength = 101;
const NSInteger kWatchTypeDataOrLength = 102;

static const long kTagMultipartBoundary = 1104;
static const long kTagMultipartEndTest = 1105;
static const long kTagMultipartHeader = 1106;

// Form Part
@implementation GCDFormPart {
    NSFileHandle * _fileHandle;
}
@synthesize headers, data, contentType, tmpFilename;

- (id) init {
    self = [super init];
    if (self) {
        self.headers = [[NSMutableDictionary alloc] init];
        self.data = [[NSMutableData alloc] init];
    }
    return self;
}

+ (NSString *) generateTemporaryFilename {
    NSString *tempFileTemplate = [NSTemporaryDirectory()
                                  stringByAppendingPathComponent:@"gcdhttpd-XXXXXX"];
    
    const char *tempFileTemplateCString =
    [tempFileTemplate fileSystemRepresentation];
    
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemps(tempFileNameCString, 0);
    
    // no need to keep it open
    close(fileDescriptor);
    
    if (fileDescriptor == -1) {
        NSLog(@"Error while creating tmp file");
        return nil;
    }
    
    NSString *tempFileName = [[NSFileManager defaultManager]
                              stringWithFileSystemRepresentation:tempFileNameCString
                              length:strlen(tempFileNameCString)];
    
    free(tempFileNameCString);
    
    return tempFileName;
}

- (void)pushData:(NSData*)newData {
    if ([self isFile]) {
        if (_fileHandle == nil) {
            self.tmpFilename = [[self class ] generateTemporaryFilename];
            _fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.tmpFilename];
        }
        [_fileHandle writeData:newData];
    } else {
        [self.data appendData:newData];
    }
}

- (void)finishParsing {
    if (self.isFile && _fileHandle != nil) {
        [_fileHandle closeFile];
        _fileHandle = nil;
    }
}

- (void)close {
    if (self.isFile && self.tmpFilename != nil) {
        NSFileManager * fileManager = [NSFileManager defaultManager];
        NSError * error;
        [fileManager removeItemAtPath:self.tmpFilename error:&error];
        if (error != nil) {
            NSLog(@"Error on removing %@: %@", self.tmpFilename, [error description]);
        }
        self.tmpFilename = nil;
    }
}

- (void)dealloc {
    [self close];
}

- (void)setContentDisposition:(NSString *)disposition {
    _contentDisposition = disposition;
    
    NSError * error;
    NSRegularExpression * regexp = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)=(\"[^\"]*\"|\\S+)" options:0 error:&error];
    
    NSAssert(error == nil, @"regexp compilation ");
    for (NSTextCheckingResult * match in [regexp matchesInString:disposition options:0 range:NSMakeRange(0, disposition.length)]) {
        NSRange nameRange = [match rangeAtIndex:1];
        NSString * attrName = [disposition substringWithRange:nameRange];
        attrName = [attrName lowercaseString];
        NSRange valueRange = [match rangeAtIndex:2];
        NSString * attrValue = [disposition substringWithRange:valueRange];
        if ([[attrValue substringToIndex:1] isEqualToString:@"\""]) {
            attrValue = [attrValue substringWithRange:NSMakeRange(1, attrValue.length - 2)];
        }
        if ([attrName isEqualToString:@"filename"]) {
            _fileName = attrValue;
        } else if ([attrName isEqualToString:@"name"]) {
            _name = attrValue;
        }
    }
}

- (BOOL)isFile {
    return self.fileName != nil;
}

@end


// GCDMultipart
@implementation GCDMultipart {
    NSString * _boundary;
    NSData * _boundaryData;
    NSData * _CRLFAndBoundaryData;
    NSMutableData * _buffer;
    NSInteger _bufferOffset;
    
    NSInteger _watchType;
    NSInteger _watchLength;
    NSData * _watchData;
    
    long _tag;
    
    GCDFormPart * _lastPart;
}

@synthesize POST, FILES;

- (id)initWithBundary:(NSString*)boundary {
    self = [super init];
    if (self) {
        _boundary = boundary;
        _boundaryData = [_boundary dataUsingEncoding:NSASCIIStringEncoding];
        _CRLFAndBoundaryData = [[NSString stringWithFormat:@"\r\n%@", _boundary] dataUsingEncoding:NSASCIIStringEncoding];
        
        _buffer = [[NSMutableData alloc] init];
        _bufferOffset = 0;
        
        self.POST = [[NSMutableDictionary alloc] init];
        self.FILES = [[NSMutableDictionary alloc] init];
        
        [self watchToData:_boundaryData tag:kTagMultipartBoundary];    
    }
    return self;
}

- (NSError *)assertTrue:(BOOL)condition message:(NSString *)message {
    if (!condition) {
        NSDictionary * excInfo = [NSDictionary dictionaryWithObject:message forKey:@"description"];
       //NSException * exception = [NSException exceptionWithName:@"MultipartException" reason:message userInfo:excInfo];
        //@throw exception;
        //[NSException raise:@"Multipartexception" format:@"%@", message, nil];
        return [NSError errorWithDomain:@"MultipartError" code:2013 userInfo:excInfo];
    }
    return nil;
}

- (void)watchToData:(NSData *)data tag:(long)tag {
    _tag = tag;
    _watchType = kWatchTypeData;
    _watchData = data;
}

- (void)watchToData:(NSData *)data orLength:(NSInteger)length tag:(long)tag {
    _tag = tag;
    _watchType = kWatchTypeDataOrLength;
    _watchData = data;
    _watchLength = length;
}

- (void)watchToLength:(NSInteger)length tag:(long)tag{
    _tag = tag;
    _watchType = kWatchTypeLength;
    _watchLength = length;
}

- (void)feed:(NSData*)data error:(NSError * __autoreleasing *)perror {
    [_buffer appendData:data];
    *perror = nil;
    NSInteger adv = [self advanceWitherror:perror];
    if (*perror != nil) {
        return;
    }
    while (adv > 0 && !self.finished) {
        adv = [self advanceWitherror:perror];
        if (*perror != nil) {
            return;
        }
    }
    if (self.finished) {
        return;
    }
    
    if (_bufferOffset > 0) {
        [_buffer shiftDataFromIndex:_bufferOffset];
        _bufferOffset = 0;
    }
}

- (NSInteger)advanceWitherror:(NSError * __autoreleasing *)perror {
    NSInteger advancedLength = 0;
    if (_watchType == kWatchTypeLength) {
        if (_buffer.length >= _watchLength + _bufferOffset) {
            NSData * data = [_buffer subdataWithRange:NSMakeRange(_bufferOffset, _watchLength)];
            _bufferOffset += _watchLength;
            *perror = [self receviedData:data finished:YES tag:_tag];
            advancedLength = _watchLength;
        }
    } else if (_watchType == kWatchTypeData) {
        NSInteger index = [_buffer firstPostionOfData:_watchData offset:_bufferOffset];
        if (index >= 0) {
            advancedLength = index + _watchData.length - _bufferOffset;
            NSData * data = [_buffer subdataWithRange:NSMakeRange(_bufferOffset, advancedLength)];            
            _bufferOffset = index + _watchData.length;
            *perror = [self receviedData:data finished:YES tag:_tag];
        }
    } else if (_watchType == kWatchTypeDataOrLength) {
        NSInteger index = [_buffer firstPostionOfData:_watchData offset:_bufferOffset];
        if (index >= 0) {
            advancedLength = index + _watchData.length - _bufferOffset;
            NSData * data = [_buffer subdataWithRange:NSMakeRange(_bufferOffset, advancedLength)];
            _bufferOffset = index + _watchData.length;
            *perror = [self receviedData:data finished:YES tag:_tag];
        } else if (_buffer.length >= _watchLength + _bufferOffset + _watchData.length) {
            NSData * data = [_buffer subdataWithRange:NSMakeRange(_bufferOffset, _watchLength)];
            _bufferOffset += _watchLength;
            *perror = [self receviedData:data finished:NO tag:_tag];
            advancedLength = _watchLength;
        }
    }
    if (*perror != nil) {
        return -1;
    }
    return advancedLength;
}

- (NSError *)receviedData:(NSData *)data finished:(BOOL)finished tag:(long)tag {
    if (tag == kTagMultipartBoundary) {
        if (_lastPart) {
            if (finished) {
                [_lastPart pushData:[data subdataWithRange:NSMakeRange(0, data.length - _CRLFAndBoundaryData.length)]];
                if (_lastPart.isFile) {
                    // A file is uploaded, store it into request.FILES
                    [_lastPart finishParsing];
                    [self.FILES setObject:_lastPart forKey:_lastPart.name];
                } else {
                    // An variable
                    NSString * strValue = [[NSString alloc] initWithData:_lastPart.data encoding:NSUTF8StringEncoding];
                    [self.POST setObject:strValue forKey:_lastPart.name];
                }
            }  else {   
                [_lastPart pushData:data];
                [self watchToData:_CRLFAndBoundaryData orLength:4096 tag:kTagMultipartBoundary];
                return nil;
            }
        }
        [self watchToLength:2 tag:kTagMultipartEndTest];
    } else if (tag == kTagMultipartEndTest) {
        if([data isEqualToData:[GCDAsyncSocket CRLFData]]) {
            _lastPart = [[GCDFormPart alloc] init];
            [self watchToData:[GCDAsyncSocket CRLFData] tag:kTagMultipartHeader];
        } else {
            NSError * error = [self assertTrue:[data isEqualToData:[@"--" dataUsingEncoding:NSASCIIStringEncoding]]
                    message:@"Unexpected chars beyond CR`LF and --"];
            if (error != nil) {
                return error;
            }
            _lastPart = nil;
            self.finished = YES;
        }
    } else if (tag == kTagMultipartHeader) {
        if (data.length > 2) {
            NSError * error = [self assertTrue:(_lastPart != nil) message:@"Part is null"];
            if (error != nil) {
                return error;
            }
            
            NSString * line = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSRange range = [line rangeOfString:@":"];
            NSString * key = [line substringToIndex:range.location];
            key = [key lowercaseString];
            NSString * value = [[line substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([key isEqualToString:@"content-disposition"]) {
                _lastPart.contentDisposition = value;
            } else if ([key isEqualToString:@"content-type"]) {
                _lastPart.contentType = value;
            } else {
                [_lastPart.headers setObject:value forKey:key];
            }
            [self watchToData:[GCDAsyncSocket CRLFData] tag:kTagMultipartHeader];
        } else {
            //
            // Empty line means multipart chunk headers are parsed
            //
            [self watchToData:_CRLFAndBoundaryData orLength:4096 tag:kTagMultipartBoundary];
        }
    }
    return nil;
}


@end
