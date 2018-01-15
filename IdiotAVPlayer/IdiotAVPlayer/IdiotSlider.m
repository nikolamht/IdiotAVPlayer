//
//  IdiotSlider.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/31.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "IdiotSlider.h"
#import "Resource.h"

@interface IdiotSlider ()
{
    NSMutableArray * loadedLayers;
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
    
    Resource * task = nil;
    
    for (NSInteger i = _caches.count - 1; i > 0; i--) {
        task = [_caches objectAtIndex:i];
        if (task.resourceType == ResourceTypeTask) {
            break;
        }
    }
    
    CGFloat lastOffset = 0;
    
    for (Resource * resource in _caches) {
        
        @autoreleasepool {
            
            CGFloat width = 0;
            
            CGFloat x = 0;
            
            if (_caches.count > 1) {
                
                if (resource.cacheLength == 0||resource.resourceType == ResourceTypeTask) {
                    continue;
                }
                
                width = ceil(self.bounds.size.width*([[NSNumber numberWithUnsignedInteger:resource.cacheLength] floatValue]/[[NSNumber numberWithUnsignedInteger:resource.fileLength] floatValue]));
                
                x = lastOffset == 0?ceil(self.bounds.size.width*([[NSNumber numberWithUnsignedInteger:resource.requestOffset] floatValue]/[[NSNumber numberWithUnsignedInteger:resource.fileLength] floatValue])):lastOffset;
                
                lastOffset += width;
                
                if (lastOffset > self.bounds.size.width) {
                    width -= lastOffset - self.bounds.size.width;
                }
                
                if (resource.resourceType == ResourceTypeNet) {
                    
                    NSInteger currentOffset = task.requestOffset + task.cacheLength;
                    
                    if (resource.requestOffset >= task.requestOffset&&
                        resource.requestOffset <  currentOffset&&
                        currentOffset <  resource.requestOffset+resource.cacheLength) {
                        
                        CGFloat scale = [[NSNumber numberWithUnsignedInteger:(currentOffset-resource.requestOffset)] floatValue]/[[NSNumber numberWithUnsignedInteger:(resource.cacheLength)] floatValue];
                        
                        CGFloat currentWidth = ceil(width*scale);
                        width = MIN(currentWidth, width);
                        
                    }else if (resource.requestOffset >= task.requestOffset&&
                              currentOffset >= resource.requestOffset+resource.cacheLength) {
                        
                    }else if (resource.requestOffset < task.requestOffset&&
                              currentOffset < resource.requestOffset+resource.cacheLength) {
                        
                        NSUInteger offset = task.requestOffset - resource.requestOffset;
                        
                        CGFloat offsetScale = [[NSNumber numberWithUnsignedInteger:offset] floatValue]/[[NSNumber numberWithUnsignedInteger:(resource.cacheLength)] floatValue];
                        
                        x += ceil(offsetScale*width);
                        
                        CGFloat scale = [[NSNumber numberWithUnsignedInteger:(task.cacheLength)] floatValue]/[[NSNumber numberWithUnsignedInteger:(resource.cacheLength)] floatValue];
                        
                        CGFloat currentWidth = ceil(width*MIN(scale, 1-offsetScale));
                        width = MIN(currentWidth, width);
                        
                    }else if (resource.requestOffset < task.requestOffset&&
                              currentOffset >= resource.requestOffset+resource.cacheLength) {
                        continue;
                    }else{
                        continue;
                    }
                    
                }
            }else{
                width = ceil(self.bounds.size.width*([[NSNumber numberWithUnsignedInteger:resource.cacheLength] floatValue]/[[NSNumber numberWithUnsignedInteger:resource.fileLength] floatValue]));
                
                x = 0;
            }
            
            CALayer * layer = [CALayer layer];
            layer.frame = CGRectMake(x, 0, width, self.bounds.size.height);
            layer.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:.6].CGColor;
            [self.layer addSublayer:layer];
            
            [loadedLayers addObject:layer];
            
        }
        
    }
    
}

@end
