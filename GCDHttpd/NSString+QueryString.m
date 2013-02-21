//
//  NSString+QueryString.m
//  GCDHttpd
//
//  Created by Zeng Ke on 13-2-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import "NSString+QueryString.h"

@implementation NSString (QueryString)

- (NSMutableDictionary *)explodeToQueryDictionary {
    return  [self explodeToQueryDictionaryUsingGlue:@"&"];
}

- (NSMutableDictionary *)explodeToQueryDictionaryUsingGlue:(NSString *)glue {
    // Explode based on outter glue
    NSArray *firstExplode = [self componentsSeparatedByString:glue];
    NSArray *secondExplode;
    
    NSInteger count = [firstExplode count];
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
    	secondExplode = [(NSString *)[firstExplode objectAtIndex:i] componentsSeparatedByString:@"="];
    	if ([secondExplode count] == 2) {
            NSString * value = [secondExplode objectAtIndex:1];
            value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString * key = [secondExplode objectAtIndex:0];
    		[returnDictionary setObject:value forKey:key];
    	} else if (secondExplode.count == 1) {
            NSString * key = [secondExplode objectAtIndex:0];
            [returnDictionary setObject:@"" forKey:key];
        }
    }
    return returnDictionary;
}

@end
