//
//  FileManager.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileManager : NSObject

+ (NSError *)moveFileAtURL:(NSURL *)srcURL toPath:(NSString *)dstPath;

+ (NSString *)cacheDirectory;

+ (NSError *)createDirectory:(NSString *)directory;

+ (NSFileHandle *)fileHandleForWritingAtPath:(NSString *)path;

+ (NSFileHandle *)fileHandleForReadingAtPath:(NSString *)path;

+ (NSMutableArray *)getResourceWithUrl:(NSURL *)url;

+ (NSString *)createSliceWithUrl:(NSURL *)url sliceName:(NSString *)name;

+ (NSString *)getCacheDirectoryWithUrl:(NSURL *)url;
@end
