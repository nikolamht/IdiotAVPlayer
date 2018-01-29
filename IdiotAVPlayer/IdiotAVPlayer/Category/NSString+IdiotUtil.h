//
//  NSString+ISNULLStr.h
//  SkyShop
//
//  Created by angela on 14-7-20.
//  Copyright (c) 2014年 angela. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (IdiotUtil)

- (BOOL) IdiotIsNullString;

- (NSString *) IdiotMD5String;

- (NSString *) formatTime:(CGFloat)time;

@end
