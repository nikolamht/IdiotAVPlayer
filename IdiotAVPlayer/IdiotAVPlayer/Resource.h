//
//  Resource.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2018/1/8.
//  Copyright © 2018年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,ResourceType) {
    ResourceTypeNet = 0,    //网络资源
    ResourceTypeLocal,      //本地资源
    ResourceTypeTask        //请求任务
};

@interface Resource : NSObject

@property (nonatomic, strong) NSURL *       requestURL;     //请求网址
@property (nonatomic, assign) long long     requestOffset;  //请求起始位置
@property (   atomic, assign) long long     cacheLength;    //缓冲长度
@property (nonatomic, assign) long long     fileLength;     //文件长度
@property (nonatomic,   copy) NSString *    cachePath;      //缓存文件路径
@property (nonatomic, assign) ResourceType  resourceType;   //资源类型

@property (nonatomic, assign) BOOL          cancel;         //是否取消请求

@end
