//
//  UIImageView+Filter.m
//  InstaLocation
//
//  Created by xiekw on 13-8-8.
//  Copyright (c) 2013年 Kaiwei.Xie. All rights reserved.
//

#import "UIImageView+Filter.h"
#import "ILSITGPUFilterGroup.h"
#import <GPUImage/GPUImagePicture.h>


#import <objc/runtime.h>


static char kILSILFilterOperationObjectKey;

@interface UIImageView (_Filter)

@property (nonatomic, strong, readwrite, setter = il_setImageFilterOperation:) NSBlockOperation *filterOperation;

@end

@implementation UIImageView(_Filter)

@dynamic filterOperation;

@end

@implementation UIImageView(Filter)

+ (NSOperationQueue *)fl_sharedOperationQueue {
    static NSOperationQueue *fl_sharedOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fl_sharedOperationQueue = [[NSOperationQueue alloc] init];
        [fl_sharedOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });
    
    return fl_sharedOperationQueue;
}

+ (FXImageCache *)fx_sharedImageCache {
    static FXImageCache *_fx_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _fx_imageCache = [[FXImageCache alloc] init];
    });
    return _fx_imageCache;
}

- (void)setImageWithFilterName:(NSString *)name placeHolder:(UIImage *)placeholder
{
    [self setImageWithFilterName:name placeHolder:placeholder compeletionHandler:nil];
}

- (void)setImageWithFilterName:(NSString *)name placeHolder:(UIImage *)placeholder compeletionHandler:(resultBlock)resultBlock
{
    [self cancelFilterOperation];
    
    if ([[self class] fx_sharedImageCache].imageHash != placeholder.hash) {
        [[self class] fx_sharedImageCache].imageHash = placeholder.hash;
        [FXImageCache cleanCache];
    };
    
    UIImage *cacheImage = [[[self class] fx_sharedImageCache] objectForKey:name];
    if (!cacheImage) {
        self.image = placeholder;
    }else {
        self.image = cacheImage;
        if (resultBlock) {
            resultBlock(cacheImage);
        }
        return;
    }
    NSBlockOperation *fOperation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *wfOperation = fOperation;
    [fOperation addExecutionBlock:^{
        UIImage *result;
        if ([wfOperation isCancelled]) {
            result = placeholder;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.image = result;
                if (resultBlock) {
                    resultBlock(result);
                }
            }];
            return;
        }
        
        ILSITGPUFilterGroup *group;
        if ([name isEqualToString:@"ILSITNashvilleFilter"]||
            [name isEqualToString:@"ILSITLordKelvinFilter"]||
            [name isEqualToString:@"ILSITBlackWhiteFilter"]||
            [name isEqualToString:@"ILSITGothamFilter"]) {
            group = [[NSClassFromString(name) alloc] init];
        }else if ([name isEqualToString:@"Origin"]) {
            result = placeholder;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.image = result;
                if (resultBlock) {
                    resultBlock(result);
                }
            }];
            return;
        }else {
            group = [[ILSITGPUFilterGroup alloc] init];
            [group addGPUFilter:[[NSClassFromString(name) alloc] init]];
        }
        
        GPUImagePicture *tempPicture = [[GPUImagePicture alloc] initWithImage:placeholder];
        [group connectPicture:tempPicture];
        [group processAllImage];
        result = [[group terminalFilter] imageFromCurrentlyProcessedOutputWithOrientation:placeholder.imageOrientation];
        group = nil;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[[self class] fx_sharedImageCache] setObject:result forKey:name];
            self.image = result;
            if (resultBlock) {
                resultBlock(result);
            }
        }];
    }];
    self.filterOperation = fOperation;
    [[[self class] fl_sharedOperationQueue] addOperation:self.filterOperation];
}


- (NSBlockOperation *)filterOperation
{
    return (NSBlockOperation *)objc_getAssociatedObject(self, &kILSILFilterOperationObjectKey);
}

- (void)il_setImageFilterOperation:(NSBlockOperation *)filterOperation
{
    objc_setAssociatedObject(self, &kILSILFilterOperationObjectKey, filterOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cancelFilterOperation
{
    [self.filterOperation cancel];
    self.filterOperation = nil;
}

@end

@implementation FXImageCache

+ (void)cleanCache
{
    [[UIImageView fx_sharedImageCache] removeAllObjects];
}

@end
