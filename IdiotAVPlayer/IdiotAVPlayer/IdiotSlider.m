//
//  IdiotSlider.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/31.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "IdiotSlider.h"
#import "IdiotResource.h"

@interface IdiotSlider ()
{
    NSMutableArray * loadedLayers;
    UISlider * slider;
}

@end

@implementation IdiotSlider

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) { return nil; }
    
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.layer.borderColor = [UIColor grayColor].CGColor;
    self.layer.borderWidth = 1/[UIScreen mainScreen].scale;
    
    [self setup];
    
    return self;
}

- (void)setup{
    loadedLayers = [[NSMutableArray alloc] init];
    
    slider = [[UISlider alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    slider.backgroundColor = [UIColor clearColor];
    slider.minimumValue = 0.0;// 设置最小值
    slider.maximumValue = 1.0;// 设置最大值
    slider.value = 0 ;// 设置初始值
    slider.continuous = YES;// 设置可连续变化
    slider.minimumTrackTintColor = [UIColor clearColor]; //滑轮左边颜色，如果设置了左边的图片就不会显示
    slider.maximumTrackTintColor = [UIColor clearColor]; //滑轮右边颜色，如果设置了右边的图片就不会显示
    slider.thumbTintColor = [UIColor colorWithRed:114.0/255.0 green:114.0/255.0 blue:114.0/255.0 alpha:0.5];//设置了滑轮的颜色，如果设置了滑轮的样式图片就不会显示
    [self addSubview:slider];
    
}

- (void)setCaches:(NSArray *)caches{
    
    _caches = caches;
    
    [self redrawing];
}

- (void)redrawing {
    
    if (loadedLayers.count) {
        for (CALayer * object in loadedLayers) {
            @autoreleasepool {
                [object removeFromSuperlayer];
            }
        }
        [loadedLayers removeAllObjects];
    }
    
    IdiotResource * task = nil;
    
    for (NSInteger i = _caches.count - 1; i > 0; i--) {
        task = [_caches objectAtIndex:i];
        if (task.resourceType == IdiotResourceTypeTask) {
            break;
        }
    }
    
    CGFloat lastOffset = 0;
    
    for (IdiotResource * resource in _caches) {
        
        @autoreleasepool {
            
            CGFloat width = 0;
            
            CGFloat x = 0;
            
            if (resource.cacheLength == 0||resource.resourceType == IdiotResourceTypeTask) {
                continue;
            }
            
            width = ceil(self.bounds.size.width*([[NSNumber numberWithLongLong:resource.cacheLength] floatValue]/[[NSNumber numberWithLongLong:resource.fileLength] floatValue]));
            
            x = lastOffset == 0?ceil(self.bounds.size.width*([[NSNumber numberWithLongLong:resource.requestOffset] floatValue]/[[NSNumber numberWithLongLong:resource.fileLength] floatValue])):lastOffset;
            
            lastOffset += width;
            
            if (lastOffset > self.bounds.size.width) {
                width -= lastOffset - self.bounds.size.width;
            }
            
            if (resource.resourceType == IdiotResourceTypeNet) {
                
                long long currentOffset = task.requestOffset + task.cacheLength;
                
                if (resource.requestOffset >= task.requestOffset&&
                    resource.requestOffset <  currentOffset&&
                    currentOffset <  resource.requestOffset+resource.cacheLength) {
                    
                    CGFloat scale = [[NSNumber numberWithLongLong:(currentOffset-resource.requestOffset)] floatValue]/[[NSNumber numberWithLongLong:(resource.cacheLength)] floatValue];
                    
                    CGFloat currentWidth = ceil(width*scale);
                    width = MIN(currentWidth, width);
                    
                }else if (resource.requestOffset >= task.requestOffset&&
                          currentOffset >= resource.requestOffset+resource.cacheLength) {
                    
                }else if (resource.requestOffset < task.requestOffset&&
                          currentOffset < resource.requestOffset+resource.cacheLength) {
                    
                    long long offset = task.requestOffset - resource.requestOffset;
                    
                    CGFloat offsetScale = [[NSNumber numberWithLongLong:offset] floatValue]/[[NSNumber numberWithLongLong:(resource.cacheLength)] floatValue];
                    
                    x += ceil(offsetScale*width);
                    
                    CGFloat scale = [[NSNumber numberWithLongLong:(task.cacheLength)] floatValue]/[[NSNumber numberWithLongLong:(resource.cacheLength)] floatValue];
                    
                    CGFloat currentWidth = ceil(width*MIN(scale, 1-offsetScale));
                    width = MIN(currentWidth, width);
                    
                }else if (resource.requestOffset < task.requestOffset&&
                          currentOffset >= resource.requestOffset+resource.cacheLength) {
                    continue;
                }else{
                    continue;
                }
                
            }
            
            CALayer * layer = [CALayer layer];
            layer.frame = CGRectMake(x, 0, width, self.bounds.size.height);
            layer.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:.6].CGColor;
            [self.layer addSublayer:layer];
            
            [loadedLayers addObject:layer];
            
        }
        
    }
    
}

- (void)setValue:(CGFloat)value animated:(BOOL)animated {
    [slider setValue:value animated:animated];
}

- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [slider addTarget:target action:action forControlEvents:controlEvents];
}

- (CGFloat)value{
    return slider.value;
}

@end
