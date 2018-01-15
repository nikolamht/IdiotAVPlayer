//
//  DownLoader.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "DownLoader.h"
#import "FileManager.h"
#import "NSString+Md5.h"
#import "NSURL+IdiotURL.h"
#import "Resource.h"

static NSString * IdiotBackgroundTaskId = @"IdiotBackgroundTaskId";
static NSString * Content_Range = @"Content-Range";

@interface DownLoader () <NSURLSessionDelegate>

@property(nonatomic , strong) NSURLSession * session;
@property(nonatomic , strong) NSOperationQueue * queue;
@property(nonatomic , strong) NSMutableDictionary * taskDic;
@property(nonatomic , strong) NSMutableArray * resources;
@property(nonatomic ,   weak) NSURLSessionDataTask * currentDataTask;
@property(nonatomic ,   weak) Resource * currentResource;
@property(   atomic , assign) BOOL writing;

@end

@implementation DownLoader

#pragma mark -
+ (DownLoader *)share
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (!self) { return nil; }
    [self session];
    self.taskDic = [[NSMutableDictionary alloc] init];
    self.writing = NO;
    return self;
}

- (void)start:(Resource *)task {
    
    if (self.currentDataTask) {
        [self.currentDataTask cancel];
    }
    
    [self.taskDic setObject:task forKey:[NSString stringWithFormat:@"%zd",task.requestOffset]];
    
    //获取本地资源
    BOOL refresh = NO;
    while (!self.writing&&!refresh) {
        self.resources = [FileManager getResourceWithUrl:task.requestURL];
        refresh = YES;
    }
    
    Resource * resource = nil;//找出对应的资源
    
    if (!self.resources.count) {//本地无资源
        resource = [[Resource alloc] init];
        resource.requestURL = task.requestURL;
        resource.requestOffset = task.requestOffset;
        resource.fileLength = task.fileLength;
        resource.cachePath = task.cachePath;
        resource.cacheLength = 0;
        resource.resourceType = ResourceTypeNet;//网络资源
    }else{//本地有资源
        
        for (Resource * obj in self.resources) {
            if (task.requestOffset >= obj.requestOffset&&
                task.requestOffset < obj.requestOffset+obj.cacheLength) {
                resource = obj;
                break;
            }
        }
        
        if (task.requestOffset > resource.requestOffset&&
            resource.resourceType == ResourceTypeNet) {
            
            NSUInteger adjustCacheLength = task.requestOffset - resource.requestOffset;
            
            Resource * net = [[Resource alloc] init];
            net.requestURL = task.requestURL;
            net.requestOffset = task.requestOffset;
            net.fileLength = task.fileLength;
            net.cachePath = task.cachePath;
            net.cacheLength = resource.cacheLength - adjustCacheLength;
            net.resourceType = ResourceTypeNet;//网络资源
            
            resource.cacheLength = adjustCacheLength;
            
            NSInteger index = [self.resources indexOfObject:resource]+1;
            
            [self.resources insertObject:net atIndex:index];
            
            resource = net;
        }
        
    }
    
    self.currentResource = resource;
    
    [self fetchDataWith:task Resource:self.currentResource];
    
}

- (void)fetchDataWith:(Resource *)sliceRequest Resource:(Resource *)resource {
    switch (resource.resourceType) {
        case ResourceTypeNet:
        {
            [self fetchFromNetwork:sliceRequest withResource:resource];
        } break;
            
        case ResourceTypeLocal:
        {
            [self fetchFromLocal:sliceRequest withResource:resource];
        } break;
            
        default:
            break;
    }
}

#pragma mark - 获取网络资源
- (void)fetchFromNetwork:(Resource *)sliceRequest withResource:(Resource *)resource{
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[resource.requestURL originalSchemeURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    if (resource.cacheLength > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld", resource.requestOffset, resource.requestOffset+resource.cacheLength-1] forHTTPHeaderField:@"Range"];
    }else{
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-", resource.requestOffset] forHTTPHeaderField:@"Range"];
    }
    NSURLSessionDataTask * task = [self.session dataTaskWithRequest:request];
    task.taskDescription = [NSString stringWithFormat:@"%zd",sliceRequest.requestOffset];
    [task resume];
    
    self.currentDataTask = task;
}
#pragma mark - 获取本地资源
- (void)fetchFromLocal:(Resource *)sliceRequest withResource:(Resource *)resource{
    
    if (sliceRequest.requestOffset == resource.requestOffset) {
        
        sliceRequest.cachePath = resource.cachePath;
        sliceRequest.fileLength = resource.fileLength;
        sliceRequest.cacheLength = resource.cacheLength;
        
        //直接开始下一个资源获取
        if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveData:)]) {
            [self.delegate didReceiveData:self];
        }
        
        [self willNextResource:sliceRequest];
        
        return;
    }
    
    NSFileHandle * readHandle = [FileManager fileHandleForReadingAtPath:resource.cachePath];
    
    NSInteger seekOffset = sliceRequest.requestOffset < resource.requestOffset?0:sliceRequest.requestOffset-resource.requestOffset;
    
    [readHandle seekToFileOffset:seekOffset];
    
    //文件过大可分次读取
    NSInteger canReadLength = resource.cacheLength-seekOffset;
    NSInteger bufferLength = 5242880; //长度大于5M分次返回数据
    
    while (canReadLength >= bufferLength) {//长度大于1M分次返回数据
        
        canReadLength -= bufferLength;
        
        NSData * responseData = [readHandle readDataOfLength:bufferLength];
        
        [self didReceiveLocalData:responseData requestTask:sliceRequest complete:canReadLength==0?YES:NO];
        
    }
    
    if (canReadLength != 0) {
        NSData * responseData = [readHandle readDataOfLength:canReadLength];
        [readHandle closeFile];
        
        [self didReceiveLocalData:responseData requestTask:sliceRequest complete:YES];
    }else{
        [readHandle closeFile];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:resource.cachePath error:nil];
    
}

#pragma mark -
- (NSURLSession *)session{
    if (!_session) {//创建支持后台的NSURLSession
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0) {
            NSURLSessionConfiguration * configure = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:IdiotBackgroundTaskId];
            _session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:self.queue];
        }else{
            NSURLSessionConfiguration * configure = [NSURLSessionConfiguration backgroundSessionConfiguration:IdiotBackgroundTaskId];
            _session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:self.queue];
        }
    }
    return _session;
}

- (NSOperationQueue *)queue{
    if (_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

#pragma mark - 下一个资源
- (void)willNextResource:(Resource *)task {
    
    if (!self.resources.count||!_currentResource) {
        return;
    }
    
    NSInteger index = [self.resources indexOfObject:_currentResource];
    
    if (index >= self.resources.count - 1) {
        return;
    }
    
    Resource * resource = [self.resources objectAtIndex:++index];
    
    self.currentResource = resource;
    
    [self fetchDataWith:task Resource:self.currentResource];
    
}

#pragma mark - 本地数据返回
- (void)didReceiveLocalData:(NSData *)data requestTask:(Resource *)task complete:(BOOL)complete {
    
    if (task.cancel) return;
    
    self.writing = YES;
    
    if (!task.cachePath.length && !task.cachePath) {
        task.cachePath = [FileManager createSliceWithUrl:task.requestURL sliceName:[NSString stringWithFormat:@"%zd-%zd",task.requestOffset,task.fileLength]];
    }
    
    NSFileHandle * handle = [FileManager fileHandleForWritingAtPath:task.cachePath];
    [handle seekToEndOfFile];
    [handle writeData:data];
    
    [handle synchronizeFile];
    [handle closeFile];
    
    task.cacheLength += data.length;
    if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveData:)]) {
        [self.delegate didReceiveData:self];
    }
    self.writing = NO;
    if (complete) {//开始下一个资源获取
        [self willNextResource:task];
    }
    
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    Resource * task = [self.taskDic objectForKey:dataTask.taskDescription];
    
    if (task.cancel) return;
    
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString * fileLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    task.fileLength = fileLength.integerValue > 0 ? fileLength.integerValue : response.expectedContentLength;
    
    if (!task.cachePath.length) {
        task.cachePath = [FileManager createSliceWithUrl:task.requestURL sliceName:[NSString stringWithFormat:@"%zd-%zd",task.requestOffset,task.fileLength]];
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    Resource * task = [self.taskDic objectForKey:dataTask.taskDescription];
    
    if (task.cancel) return;
    
    self.writing = YES;
    NSFileHandle * handle = [FileManager fileHandleForWritingAtPath:task.cachePath];
    [handle seekToEndOfFile];
    [handle writeData:data];
    
    [handle synchronizeFile];
    [handle closeFile];
    self.writing = NO;
    
    task.cacheLength += data.length;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveData:)]) {
        [self.delegate didReceiveData:self];
    }
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    Resource * datatask = [self.taskDic objectForKey:task.taskDescription];
    
    if (datatask.cancel) {
//        NSLog(@"下载取消");
    }else {
        
        if (!error) {
            //开始下一个资源获取
            [self willNextResource:datatask];
        }
        
    }
    
    NSLog(@"didCompleteWithError");
}

//最终处理
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    
    if (self.backgroundSessionCompletionHandler) {
        __weak typeof(self) weakself = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            __strong typeof(weakself) strongself = weakself;
            strongself.backgroundSessionCompletionHandler();
        }];
    }
    
}
@end
