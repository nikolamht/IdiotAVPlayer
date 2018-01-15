//
//  NSURL+SULoader.m
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import "NSURL+IdiotURL.h"

@implementation NSURL (IdiotURL)

- (NSURL *)idiotSchemeURL {
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    components.scheme = @"idiot";
    return [components URL];
}

- (NSURL *)originalSchemeURL {
    NSURLComponents * components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    components.scheme = @"http";
    return [components URL];
}

@end
