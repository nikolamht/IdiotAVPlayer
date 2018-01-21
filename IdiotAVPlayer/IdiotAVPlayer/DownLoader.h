//
//  DownLoader.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Resource;
@class DownLoader;

@protocol DownLoaderDataDelegate <NSObject>

@required

- (void)didReceiveData:(DownLoader * __weak)downLoader;

@end

@interface DownLoader : NSObject

@property (nonatomic, copy)             void (^backgroundSessionCompletionHandler)();
@property (nonatomic, weak)             id<DownLoaderDataDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray * resources;

+ (DownLoader *)share;
- (void)start:(Resource *)task;
- (void)cancel;
- (void)resume;

@end
