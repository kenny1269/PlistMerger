//
//  NSMutableDictionary+Merge.h
//  PlistView
//
//  Created by junhai on 2020/3/12.
//  Copyright © 2020 junhai. All rights reserved.
//

#import <AppKit/AppKit.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (Merge)

- (void)mergeWithData:(id)data;

@end

NS_ASSUME_NONNULL_END
