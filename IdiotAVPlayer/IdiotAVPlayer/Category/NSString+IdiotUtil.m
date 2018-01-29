//
//  NSString+ISNULLStr.m
//  SkyShop
//
//  Created by angela on 14-7-20.
//  Copyright (c) 2014年 angela. All rights reserved.
//

#import "NSString+IdiotUtil.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (IdiotUtil)

- (BOOL) IdiotIsNullString{

    if ([self isKindOfClass:[NSNull class]] )
    {
        return YES;
    }
    
    if (self==NULL || self==nil || [self isEqualToString:@"null"]|| [self isEqualToString:@"<null>"] || [self isEqual:[NSNull null]] || self.length==0 ) {
        return YES;
    }
    return NO;
}

- (NSString *) IdiotMD5String
{
    if ([self IdiotIsNullString]) { return nil; }
    
    const char *cStringToHash = [self UTF8String];
    unsigned char hash[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStringToHash, (CC_LONG)(strlen(cStringToHash)), hash);
    
    NSMutableString *hashString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
    {
        [hashString appendFormat:@"%02X", hash[i]];
    }
    NSString *result = [NSString stringWithString:hashString];
    return result;
}

- (NSString *) formatTime:(CGFloat)time
{
    long videocurrent = ceil(time);
    
    NSString *str = nil;
    if (videocurrent < 3600) {
        str =  [NSString stringWithFormat:@"%02li:%02li",lround(floor(videocurrent/60.f)),lround(floor(videocurrent/1.f))%60];
    } else {
        str =  [NSString stringWithFormat:@"%02li:%02li:%02li",lround(floor(videocurrent/3600.f)),lround(floor(videocurrent%3600)/60.f),lround(floor(videocurrent/1.f))%60];
    }
    
    return str;
}

@end
