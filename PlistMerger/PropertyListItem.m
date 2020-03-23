//
//  PropertyListItem.m
//  PlistView
//
//  Created by junhai on 2020/3/10.
//  Copyright © 2020 junhai. All rights reserved.
//

#import "PropertyListItem.h"

#import "NSMutableDictionary+Merge.h"

@interface PropertyListItem ()

@property (nonatomic, strong) NSMutableDictionary *childrenDict;

@end

@implementation PropertyListItem

+ (instancetype)rootItemWithData:(id)data {
    return [[PropertyListItem alloc] initWithKey:@"Root" value:[data mutableCopy]];
}

- (instancetype)initWithKey:(NSString *)key value:(id)value {
    if (self = [super init]) {
        self.key = key;
        self.value = value;
    }
    return self;
}

#pragma mark -

- (BOOL)expandable {
    return [self.value isKindOfClass:[NSDictionary class]] || [self.value isKindOfClass:[NSArray class]];
}

- (NSMutableArray *)children {
    if (!_children) {
        _children = [NSMutableArray array];
        if ([self.value isKindOfClass:[NSDictionary class]]) {
            NSEnumerator *enumerator = [self.value keyEnumerator];
            id nextObject;
            while (nextObject = [enumerator nextObject]) {
                PropertyListItem *item = [[self.class alloc] initWithKey:nextObject value:self.value[nextObject]];
                [_children addObject:item];
                [self.childrenDict setValue:item forKey:nextObject];
            }
        } else if ([self.value isKindOfClass:[NSArray class]]) {
            NSEnumerator *enumerator = [self.value objectEnumerator];
            id nextObject;
            while (nextObject = [enumerator nextObject]) {
                PropertyListItem *item = [[self.class alloc] initWithKey:nil value:nextObject];
                [_children addObject:item];
            }
        }
    }
    return _children;
}

#pragma mark -

- (void)setValue:(id)value {
    _value = value;
    
    NSString *className = NSStringFromClass([(NSObject *)value class]);
    for (NSString *typeName in typeNames()) {
        if ([className containsString:typeName]) {
            self.type = typeName;
            return;
        }
    }
}

static NSArray *typeNames() {
    return @[@"Dictionary", @"Array", @"Data", @"Date", @"Number", @"String", @"Boolean"];
}

- (NSMutableDictionary *)childrenDict {
    if (!_childrenDict) {
        _childrenDict = [NSMutableDictionary dictionary];
    }
    return _childrenDict;
}

@end

@implementation MergedItem

+ (instancetype)itemWithOriginItem:(PropertyListItem *)originItem mergeWithData:(id)data {
    id value;
    if ([originItem.value isKindOfClass:[NSDictionary class]]) {
        value = [[NSMutableDictionary alloc] initWithDictionary:originItem.value copyItems:YES];
    } else if ([originItem.value isKindOfClass:[NSArray class]]) {
        value = [[NSMutableArray alloc] initWithArray:originItem.value copyItems:YES];
    }
    MergedItem *mergedItem = [[MergedItem alloc] initWithKey:originItem.key value:value];
    [mergedItem mergeWithData:[data mutableCopy]];
    [mergedItem checkDifferenceWithOriginItem:originItem];
    return mergedItem;
}

- (void)mergeWithData:(id)data {
    if ([self.value isKindOfClass:[NSArray class]]) {
        [(NSMutableArray *)self.value addObject:data];
    } else if ([self.value isKindOfClass:[NSDictionary class]]) {
        [(NSMutableDictionary *)self.value mergeWithData:data];
    } else {
        NSLog(@"cannot merge");
    }
}

- (BOOL)checkDifferenceWithOriginItem:(PropertyListItem *)originItem {
    if ([self.value isKindOfClass:[NSArray class]] && [originItem.value isKindOfClass:[NSArray class]]) {
        if (![(NSArray *)self.value isEqualToArray:originItem.value]) {
            for (MergedItem *item in self.children) {
                item.isDifferent = YES;
            }
            for (PropertyListItem *item in originItem.children) {
                DeletedItem *deletedItem = [[DeletedItem alloc] initWithKey:item.key value:item.value];
                [self.children insertObject:deletedItem atIndex:[originItem.children indexOfObject:item]];
            }
        }
        
    } else if ([self.value isKindOfClass:[NSDictionary class]] && [originItem.value isKindOfClass:[NSDictionary class]]) {
        NSMapTable *differenceMap = [NSMapTable weakToWeakObjectsMapTable];
        for (NSUInteger i = 0; i < self.children.count; i++) {
            NSString *key = self.childrenDict.allKeys[i];
            MergedItem *mergedChildItem = self.childrenDict[key];
            if (![originItem.childrenDict.allKeys containsObject:key]) {
                mergedChildItem.isDifferent = YES;
                continue;
            } else {
                PropertyListItem *originChildItem = originItem.childrenDict[key];
                BOOL isDifferent = [mergedChildItem checkDifferenceWithOriginItem:originChildItem];
                if (isDifferent) {
                    [differenceMap setObject:originChildItem forKey:mergedChildItem];
                }
            }
        }
        NSEnumerator *keyEnumerator = differenceMap.keyEnumerator;
        id next;
        while (next = [keyEnumerator nextObject]) {
            PropertyListItem *originChildItem = [differenceMap objectForKey:next];
            [self.children insertObject:[[DeletedItem alloc] initWithKey:originChildItem.key value:originChildItem.value] atIndex:[self.children indexOfObject:next]];
        }
    } else if ([self.value isKindOfClass:[NSString class]] && [originItem.value isKindOfClass:[NSString class]]) {
        if (![(NSString *)self.value isEqualToString:originItem.value]) {
            self.isDifferent = YES;
            return YES;
        }
    } else if ([self.value isKindOfClass:[NSData class]] && [originItem.value isKindOfClass:[NSData class]]) {
        if (![(NSData *)self.value isEqualToData:originItem.value]) {
            self.isDifferent = YES;
            return YES;
        }
    } else if ([self.value isKindOfClass:[NSDate class]] && [originItem.value isKindOfClass:[NSDate class]]) {
        if (![(NSDate *)self.value isEqualToDate:originItem.value]) {
            self.isDifferent = YES;
            return YES;
        }
    } else if ([self.value isKindOfClass:[NSNumber class]] && [originItem.value isKindOfClass:[NSNumber class]]) {
        if (![(NSNumber *)self.value isEqualToNumber:originItem.value]) {
            self.isDifferent = YES;
            return YES;
        }
    } else if ([self.value isKindOfClass:[NSNumber class]]) {
        if (![(NSNumber *)self.value isEqualToNumber:originItem.value]) {
            self.isDifferent = YES;
            return YES;
        }
    } else {
        if (![self.value isEqual:originItem.value]) {
            self.isDifferent = YES;
            return YES;
        }
    }
    return NO;
}

- (NSMutableArray *)children {
    if (!_children) {
        _children = [super children];
        if (self.isDifferent) {
            for (MergedItem *item in _children) {
                item.isDifferent = YES;
            }
        }
    }
    return _children;
}

@end

@implementation DeletedItem

@end
