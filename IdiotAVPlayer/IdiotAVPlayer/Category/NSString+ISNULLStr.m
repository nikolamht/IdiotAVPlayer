//
//  NSString+ISNULLStr.m
//  SkyShop
//
//  Created by angela on 14-7-20.
//  Copyright (c) 2014年 angela. All rights reserved.
//

#import "NSString+ISNULLStr.h"

@implementation NSString (ISNULLStr)

- (BOOL) isNullString{

    if ([self isKindOfClass:[NSNull class]] )
    {
        return YES;
    }
    
    if (self==NULL || self==nil || [self isEqualToString:@"null"]|| [self isEqualToString:@"<null>"] || [self isEqual:[NSNull null]] || self.length==0 ) {
        return YES;
    }
    return NO;
}

@end
