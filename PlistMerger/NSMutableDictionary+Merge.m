//
//  NSMutableDictionary+Merge.m
//  PlistView
//
//  Created by junhai on 2020/3/12.
//  Copyright © 2020 junhai. All rights reserved.
//

#import "NSMutableDictionary+Merge.h"

#import <AppKit/AppKit.h>


@implementation NSMutableDictionary (Merge)

- (void)mergeWithData:(id)data {
    if ([data isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in [data allKeys]) {
            if ([self.allKeys containsObject:key]) {
                NSObject *originValue = self[key];
                NSObject *newValue = data[key];
                if ([originValue isKindOfClass:[NSArray class]] && [newValue isKindOfClass:[NSArray class]]) {
                    [self setObject:newValue forKey:key];
                } else if ([originValue isKindOfClass:[NSDictionary class]] && [newValue isKindOfClass:[NSDictionary class]]) {
                    originValue = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)originValue];
                    self[key] = originValue;
                    [(NSMutableDictionary *)originValue mergeWithData:newValue];
                } else {
                    [self setObject:newValue forKey:key];
                }
            } else {
                [self addEntriesFromDictionary:@{key:data[key]}];
            }
        }
    } else {
        [NSException raise:@"Merge error" format:@"merge value to a dictionary should specify a key: %@", data];
    }
}

@end
