//
//  PropertyListItem.h
//  PlistView
//
//  Created by junhai on 2020/3/10.
//  Copyright © 2020 junhai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PropertyListItem : NSObject
{
    @public
    NSMutableArray *_children;
}

@property (nonatomic, nullable, copy) NSString *key;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong) id value;
@property (nonatomic, assign) BOOL expandable;

@property (nonatomic, nullable, strong) NSMutableArray *children;

+ (instancetype)rootItemWithData:(id)data;

@end

@interface MergedItem : PropertyListItem

+ (instancetype)itemWithOriginItem:(PropertyListItem *)originItem mergeWithData:(id)data;

- (void)mergeWithData:(id)data;

@property (nonatomic, assign) BOOL isNew;

@property (nonatomic, weak) id originValue;

@end

NS_ASSUME_NONNULL_END
