//
//  ResourceLoader.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ResourceLoaderCacheProgressDelegate <NSObject>

@required

- (void)didCacheProgressChange:(NSArray *)cacheProgressList;

@end

@interface ResourceLoader : NSObject <AVAssetResourceLoaderDelegate>

@property(nonatomic , weak) id<ResourceLoaderCacheProgressDelegate> delegate;
@property(nonatomic , assign) BOOL seek;

@end
