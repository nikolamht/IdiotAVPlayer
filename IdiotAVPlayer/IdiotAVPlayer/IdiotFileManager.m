//
//  FileManager.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//

#import "IdiotFileManager.h"
#import "IdiotResource.h"
#import "NSString+IdiotUtil.h"

static NSString * cachePath;

@implementation IdiotFileManager

+ (NSError *)moveFileAtURL:(NSURL *)srcURL toPath:(NSString *)dstPath
{
    NSError * e = nil;
    
    if (!dstPath) {
        e = [NSError errorWithDomain:@"error filePath == nil" code:-1 userInfo:NULL];
        return e;
    }
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:dstPath] ) {
        [fileManager removeItemAtPath:dstPath error:&e];
        if (e) {
            return e;
        }
    }
    
    NSURL * dstURL = [NSURL fileURLWithPath:dstPath];
    
    [fileManager moveItemAtURL:srcURL toURL:dstURL error:&e];
    
    return e;
}

+ (NSString *)cacheDirectory{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [[paths firstObject] copy];
    });
    
    return cachePath;
}

+ (NSError *)createDirectory:(NSString *)directory
{
    NSError * e = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&e];
    }
    
    return e;
}

+ (NSFileHandle *)fileHandleForWritingAtPath:(NSString *)path {
    
    NSFileManager * manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:path]) {
        
        return [NSFileHandle fileHandleForUpdatingAtPath:path];
        
    }
    
    if ([manager createFileAtPath:path contents:nil attributes:nil]) {
        return [NSFileHandle fileHandleForWritingAtPath:path];
    }
    
    return nil;
}

+ (NSFileHandle *)fileHandleForReadingAtPath:(NSString *)path {
    NSFileManager * manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:path]) {
        return [NSFileHandle fileHandleForReadingAtPath:path];
    }
    return nil;
}

+ (NSMutableArray *)getResourceWithUrl:(NSURL *)url {
    
    NSString * cachePath = [IdiotFileManager getCacheDirectoryWithUrl:url];
    
    NSMutableArray * resourceArr = [[NSMutableArray alloc] init];
    
    long long fileLength = 0;
    
    if (!cachePath) {
        return resourceArr;
    }
    
    NSFileManager * manager = [NSFileManager defaultManager];
    
    NSEnumerator * childsEnumerator = [[manager subpathsAtPath:cachePath] objectEnumerator];
    
    NSString * fileName;
    
    while ((fileName = [childsEnumerator nextObject]) != nil){
        
        if (![[fileName pathExtension] isEqualToString:@"idiot"]) {
            continue;
        }
        
        @autoreleasepool {
            NSString * filePath = [cachePath stringByAppendingPathComponent:fileName];
            
            NSArray * key_length = [[fileName stringByDeletingPathExtension] componentsSeparatedByString:@"-"];
            
            NSString * key = [key_length firstObject];
            
            IdiotResource * local = [[IdiotResource alloc] init];
            local.requestURL = url;
            local.requestOffset = [key longLongValue];
            local.fileLength = [[key_length lastObject] longLongValue];
            if (fileLength == 0) {
                fileLength = local.fileLength;
            }
            local.cachePath = filePath;
            local.cacheLength =  [[manager attributesOfItemAtPath:filePath error:nil]fileSize];
            local.resourceType = IdiotResourceTypeLocal;//本地资源
            [resourceArr addObject:local];
        }
        
    }
    
    if (!resourceArr.count) {
        return resourceArr;
    }
    //排序合并
    [resourceArr sortUsingComparator:^NSComparisonResult(IdiotResource * _Nonnull obj1, IdiotResource * _Nonnull obj2) {
        NSComparisonResult result = [[NSNumber numberWithLongLong:obj1.requestOffset] compare:[NSNumber numberWithLongLong:obj2.requestOffset]];
        return result;
    }];
    
    IdiotResource * lastResource = nil;
    
    NSMutableArray * deleteResource = [[NSMutableArray alloc] init];
    
    NSMutableArray * addResource = [[NSMutableArray alloc] init];
    
    for (IdiotResource * resource in resourceArr) {
     
        @autoreleasepool {
            
            if (lastResource) {
                
                if (resource.requestOffset >= lastResource.requestOffset&&
                    resource.requestOffset+resource.cacheLength <= lastResource.requestOffset+lastResource.cacheLength) {
                    [manager removeItemAtPath:resource.cachePath error:nil];
                    [deleteResource addObject:resource];
                    continue;
                }
                
                if (resource.requestOffset >= lastResource.requestOffset&&
                    resource.requestOffset <= lastResource.requestOffset+lastResource.cacheLength&&
                    resource.requestOffset+resource.cacheLength > lastResource.requestOffset+lastResource.cacheLength) {
                    
                    //合并slice和lastSlice
                    
                    NSFileHandle * updateHandle = [NSFileHandle fileHandleForWritingAtPath:lastResource.cachePath];
                    
                    NSFileHandle * readHandle = [NSFileHandle fileHandleForReadingAtPath:resource.cachePath];
                    
                    [updateHandle seekToEndOfFile];
                    
                    long long seekOffset = lastResource.requestOffset+lastResource.cacheLength-resource.requestOffset;
                    
                    [readHandle seekToFileOffset:seekOffset];
                    
                    [updateHandle writeData:[readHandle readDataToEndOfFile]];
                    
                    [readHandle closeFile];
                    
                    [updateHandle synchronizeFile];
                    [updateHandle closeFile];
                    
                    //调整lastResource
                    lastResource.cacheLength = resource.cacheLength+lastResource.cacheLength-seekOffset;
                    //删除文件(失败没关系)
                    [manager removeItemAtPath:resource.cachePath error:nil];
                    //删除resource
                    [deleteResource addObject:resource];
                    
                    continue;
                }
                
                if (resource.requestOffset > lastResource.requestOffset+lastResource.cacheLength) {
                    
                    IdiotResource * net = [[IdiotResource alloc] init];
                    net.requestURL = url;
                    net.requestOffset = lastResource.requestOffset+lastResource.cacheLength;
                    net.fileLength = fileLength;
                    net.cachePath = [[cachePath stringByAppendingString:@"/"] stringByAppendingString:[NSString stringWithFormat:@"%zd-%zd.idiot",net.requestOffset,fileLength]];
                    net.cacheLength = resource.requestOffset - net.requestOffset;
                    net.resourceType = IdiotResourceTypeNet;//网络资源
                    
                    [addResource addObject:net];
                    
                    lastResource = resource;
                    
                    continue;
                }
                
            }
            
            if (!lastResource) {
                lastResource = resource;
                continue;
            }
        }
        
    }
    
    [resourceArr removeObjectsInArray:deleteResource];
    
    [resourceArr addObjectsFromArray:addResource];
    
    //排序
    [resourceArr sortUsingComparator:^NSComparisonResult(IdiotResource * _Nonnull obj1, IdiotResource * _Nonnull obj2) {
        NSComparisonResult result = [[NSNumber numberWithLongLong:obj1.requestOffset] compare:[NSNumber numberWithLongLong:obj2.requestOffset]];
        return result;
    }];
    
    //检查头
    IdiotResource * resource = nil;
    
    resource = [resourceArr firstObject];
    
    if (resource.requestOffset != 0) {
        
        IdiotResource * net = [[IdiotResource alloc] init];
        net.requestURL = url;
        net.requestOffset = 0;
        net.fileLength = fileLength;
        net.cachePath = [[cachePath stringByAppendingString:@"/"] stringByAppendingString:[NSString stringWithFormat:@"0-%zd.idiot",fileLength]];
        net.cacheLength = resource.requestOffset;
        net.resourceType = IdiotResourceTypeNet;//网络资源
        
        [resourceArr insertObject:net atIndex:0];
    }
    
    //检查尾
    resource = [resourceArr lastObject];
    
    if (resource.requestOffset + resource.cacheLength < resource.fileLength) {
        
        IdiotResource * net = [[IdiotResource alloc] init];
        net.requestURL = url;
        net.requestOffset = resource.requestOffset + resource.cacheLength;
        net.fileLength = fileLength;
        net.cachePath = [[cachePath stringByAppendingString:@"/"] stringByAppendingString:[NSString stringWithFormat:@"%zd-%zd.idiot",net.requestOffset,fileLength]];
        net.cacheLength = resource.fileLength-(resource.requestOffset+resource.cacheLength);
        net.resourceType = IdiotResourceTypeNet;//网络资源
        
        [resourceArr addObject:net];
    }
    
    return resourceArr;
}

+ (NSString *)createSliceWithUrl:(NSURL *)url sliceName:(NSString *)name {
    
    NSString * cacheFilePath = nil;
    
    NSString * dirPath = [[[IdiotFileManager cacheDirectory] stringByAppendingString:@"/"] stringByAppendingString:[url.absoluteString IdiotMD5String]];
    
    if (![IdiotFileManager createDirectory:dirPath]) {//创建文件夹成功
        cacheFilePath = [[dirPath stringByAppendingString:@"/"] stringByAppendingString:[NSString stringWithFormat:@"%@.idiot",name]];
        return cacheFilePath;
    }
    
    return cacheFilePath;
}

+ (NSString *)getCacheDirectoryWithUrl:(NSURL *)url {
    
    NSString * dirPath = [[[IdiotFileManager cacheDirectory] stringByAppendingString:@"/"] stringByAppendingString:[url.absoluteString IdiotMD5String]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        return nil;
    }
    
    return dirPath;
}

@end
