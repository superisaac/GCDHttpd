//
//  GHHandler.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-1-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import "GCDRouterRole.h"

@implementation GCDRouterRole {
    NSRegularExpression * _pathRegexp;
    NSMutableArray * patternValues;
    NSMutableArray * patternTypes;
}

@synthesize method, target, action, userData;

+ (NSRegularExpression * )pathSpliter {
    static NSRegularExpression * _finder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError * error;
        _finder = [NSRegularExpression regularExpressionWithPattern:@"/|([^/]+)" options:NSRegularExpressionUseUnicodeWordBoundaries error:&error];
        if (error != nil) {
            NSLog(@"Error on compiling pattern %@", [error description]);
        }
    });
    return _finder;
}

- (void)setPathPattern:(NSString *)pathPattern {
    _pathPattern = pathPattern;
    patternTypes = [[NSMutableArray alloc] init];
    patternValues = [[NSMutableArray alloc] init];
    
    NSArray * matches = [[[self class] pathSpliter] matchesInString:pathPattern options:NSMatchingReportCompletion range:NSMakeRange(0, pathPattern.length)];
    BOOL metTrail = NO;
    for (NSTextCheckingResult * match in matches) {
        if (metTrail) {
            NSLog(@"::%@ must be at the tail of pattern", [patternValues lastObject]);
            break;
        }
        NSRange range = match.range;
        NSString * entry = [pathPattern substringWithRange:range];
        
        NSString * pType = @"C";
        NSString * pValue = entry;

        if ([entry isEqualToString:@"/"]) {
            pType = @"/";
        } else if (entry.length > 2 && [[entry substringToIndex:2] isEqualToString:@"::"]) {
            pType = @"::";
            pValue = [entry substringFromIndex:2];
            metTrail = YES;
        } else if (entry.length > 1 && [[entry substringToIndex:1] isEqualToString:@":"]) {
            pType = @":";
            pValue = [entry substringFromIndex:1];
        }
        [patternTypes addObject:pType];
        [patternValues addObject:pValue];
    }
}

- (NSDictionary *)matchMethod:(NSString *)httpMethod path:(NSString *)path {
    if (![self.method isEqualToString:httpMethod]) {
        return nil;
    }
    
    NSArray * matches = [[[self class] pathSpliter] matchesInString:path options:NSMatchingReportCompletion range:NSMakeRange(0, path.length)];
    BOOL useTrail = NO;
    NSMutableDictionary * bindings = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i<patternTypes.count; i++) {
        NSString * entry = @"";
        NSInteger location = path.length;
        if (i < matches.count) {
            NSTextCheckingResult * match = [matches objectAtIndex:i];
            location = match.range.location;
            entry = [path substringWithRange:match.range];
        }

        NSString * pType = [patternTypes objectAtIndex:i];
        NSString * pValue = [patternValues objectAtIndex:i];
        if ([pType isEqualToString:@"C"] || [pType isEqualToString:@"/"]) {
            if (![pValue isEqualToString:entry]) {
                return nil;
            }
        } else if ([pType isEqualToString:@":"]) {
            [bindings setObject:entry forKey:pValue];
        } else if ([pType isEqualToString:@"::"]) {
            NSString * rest = @"";
            if (location < path.length) {
                rest = [path substringFromIndex:location];
            }
            [bindings setObject:rest forKey:pValue];
            useTrail = YES;
            break;
        }
    }
    if (!useTrail) {
        if (matches.count != patternTypes.count) {
            return nil;
        }
    }
    return bindings;
}

@end
