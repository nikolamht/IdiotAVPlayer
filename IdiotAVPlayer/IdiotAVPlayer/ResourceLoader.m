//
//  ResourceLoader.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ResourceLoader.h"
#import "FileManager.h"
#import "DownLoader.h"
#import "NSURL+IdiotURL.h"
#import "Resource.h"
#import "ResourceTask.h"

@interface ResourceLoader () <DownLoaderDataDelegate>
{
    dispatch_semaphore_t semaphore;
}
@property (nonatomic, strong) NSMutableArray * taskList;
@property (nonatomic,   weak) Resource * currentResource;
@property (nonatomic, strong) NSOperationQueue * playQueue;

@end

@implementation ResourceLoader


- (instancetype)init{
    self = [super init];
    if (!self) { return nil; }
    self.taskList = [[NSMutableArray alloc] init];
    self.playQueue = [[NSOperationQueue alloc] init];
    self.playQueue.maxConcurrentOperationCount = 1;
    semaphore = dispatch_semaphore_create(1);
    self.seek = NO;
    return self;
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    [self addLoadingRequest:loadingRequest];
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    [self removeLoadingRequest:loadingRequest];
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSArray * temptaskList = [NSArray arrayWithArray:self.taskList];
    dispatch_semaphore_signal(semaphore);
    
    ResourceTask * deleteTask = nil;
    
    for (ResourceTask * task in temptaskList) {
        if ([task.loadingRequest isEqual:loadingRequest]) {
            deleteTask = task;
            break;
        }
    }
    
    if (deleteTask) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [self.taskList removeObject:deleteTask];
        dispatch_semaphore_signal(semaphore);
    }
    
}

- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    if (self.currentResource) {
        
        if (loadingRequest.dataRequest.requestedOffset >= self.currentResource.requestOffset &&
            loadingRequest.dataRequest.requestedOffset <= self.currentResource.requestOffset + self.currentResource.cacheLength) {
            
            ResourceTask * task = [[ResourceTask alloc] init];
            task.loadingRequest = loadingRequest;
            task.resource = self.currentResource;
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            [self.taskList addObject:task];
            dispatch_semaphore_signal(semaphore);
            [self processRequestList];
            
        }else{
            
            if (self.seek) {
                [self newTaskWithLoadingRequest:loadingRequest];
            }else{
                
                ResourceTask * task = [[ResourceTask alloc] init];
                task.loadingRequest = loadingRequest;
                task.resource = self.currentResource;
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                [self.taskList addObject:task];
                dispatch_semaphore_signal(semaphore);
            }
            
        }
        
    }else {
        [self newTaskWithLoadingRequest:loadingRequest];
    }
}

- (void)newTaskWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    NSUInteger fileLength = 0;
    
    if (self.currentResource) {
        fileLength = self.currentResource.fileLength;
        self.currentResource.cancel = YES;
    }
    
    Resource * resource = [[Resource alloc] init];
    resource.requestURL = loadingRequest.request.URL;
    resource.requestOffset = loadingRequest.dataRequest.requestedOffset;
    resource.resourceType = ResourceTypeTask;
    if (fileLength > 0) {
        resource.fileLength = fileLength;
    }
    
    ResourceTask * task = [[ResourceTask alloc] init];
    task.loadingRequest = loadingRequest;
    task.resource = resource;
    
    self.currentResource = resource;
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [self.taskList addObject:task];
    dispatch_semaphore_signal(semaphore);
    
    [DownLoader share].delegate = self;
    [[DownLoader share] start:self.currentResource];
    
    self.seek = NO;
}

- (void)processRequestList {
    @synchronized (self) {
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSArray * temptaskList = [NSArray arrayWithArray:self.taskList];
        dispatch_semaphore_signal(semaphore);
        
        for (ResourceTask * task in temptaskList) {

            NSInvocationOperation * invoke = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(finishLoadingWithLoadingRequest:) object:task];
            
            [_playQueue addOperation:invoke];
            
        }
        
    }
}

- (void)finishLoadingWithLoadingRequest:(ResourceTask *)task {
    
    //填充信息
    task.loadingRequest.contentInformationRequest.contentType = @"video/mp4";
    task.loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    task.loadingRequest.contentInformationRequest.contentLength = task.resource.fileLength;
    
    if (task.resource.fileLength <= 0) {
        DLogDebug(@"requestTask.fileLength <= 0");
    }
    
    //读文件，填充数据
    NSUInteger cacheLength = task.resource.cacheLength;
    NSUInteger requestedOffset = task.loadingRequest.dataRequest.requestedOffset;
    if (task.loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = task.loadingRequest.dataRequest.currentOffset;
    }
    
    if (requestedOffset < task.resource.requestOffset) {
        return;
    }
    
    NSUInteger paddingOffset = requestedOffset - task.resource.requestOffset;
    
    NSUInteger canReadLength = cacheLength - paddingOffset;
    
    if (canReadLength <= 0) {
        return;
    }
    
    NSUInteger respondLength = MIN(canReadLength, task.loadingRequest.dataRequest.requestedLength);
    
    NSFileHandle * handle = [FileManager fileHandleForReadingAtPath:task.resource.cachePath];
    
    [handle seekToFileOffset:paddingOffset];
    
    [task.loadingRequest.dataRequest respondWithData:[handle readDataOfLength:respondLength]];
    
    [handle closeFile];
    
    //如果完全响应了所需要的数据，则完成
    NSUInteger nowendOffset = requestedOffset + canReadLength;
    NSUInteger reqEndOffset = task.loadingRequest.dataRequest.requestedOffset + task.loadingRequest.dataRequest.requestedLength;
    if (nowendOffset >= reqEndOffset) {
        [task.loadingRequest finishLoading];
        
        [self removeLoadingRequest:task.loadingRequest];
        
        return;
    }
    
}

#pragma mark - DownLoaderDataDelegate
- (void)didReceiveData:(DownLoader *__weak)downLoader{
    
    [self processRequestList];
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(didCacheProgressChange:)]) {
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakself) strongself = weakself;
            
            NSMutableArray * caches = [downLoader.resources mutableCopy];
            
            [caches addObject:self.currentResource];
            
            [strongself.delegate didCacheProgressChange:caches];
        });
    }
    
}

@end
