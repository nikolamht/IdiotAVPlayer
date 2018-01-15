//
//  ResourceTask.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2018/1/12.
//  Copyright © 2018年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVAssetResourceLoadingRequest;
@class Resource;

@interface ResourceTask : NSObject

@property(nonatomic , strong) AVAssetResourceLoadingRequest * loadingRequest;
@property(nonatomic , strong) Resource * resource;

@end
