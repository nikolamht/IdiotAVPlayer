//
//  DownLoader.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IdiotResource;
@class IdiotDownLoader;

@protocol DownLoaderDataDelegate <NSObject>

@required

- (void)didReceiveData:(IdiotDownLoader * __weak)downLoader;

@end

@interface IdiotDownLoader : NSObject

@property (nonatomic, copy)             void (^backgroundSessionCompletionHandler)();
@property (nonatomic, weak)             id<DownLoaderDataDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray * resources;

+ (IdiotDownLoader *)share;
- (void)start:(IdiotResource *)task;
- (void)cancel;
- (void)resume;

@end
