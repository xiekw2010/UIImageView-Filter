//
//  UIImageView+Filter.h
//  InstaLocation
//
//  Created by xiekw on 13-8-8.
//  Copyright (c) 2013年 Kaiwei.Xie. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^resultBlock)(UIImage *resultImage);


@interface UIImageView (Filter)

- (void)setImageWithFilterName:(NSString *)name placeHolder:(UIImage *)placeholder;
- (void)setImageWithFilterName:(NSString *)name placeHolder:(UIImage *)placeholder compeletionHandler:(resultBlock)resultBlock;

- (void)cancelFilterOperation;

@end


@interface FXImageCache : NSCache

@property (nonatomic, assign) NSUInteger imageHash;

+ (void)cleanCache;

@end