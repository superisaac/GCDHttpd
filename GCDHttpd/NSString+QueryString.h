//
//  NSString+QueryString.h
//  GCDHttpd
//
//  Created by Zeng Ke on 13-2-16.
//  Copyright (c) 2013 zengke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (QueryString)
- (NSMutableDictionary *)explodeToQueryDictionary;
- (NSMutableDictionary *)explodeToQueryDictionaryUsingGlue:(NSString *)glue;

@end
