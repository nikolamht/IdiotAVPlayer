//
//  IdiotSlider.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/31.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IdiotSlider : UIView

@property(nonatomic ,   copy) NSArray * _Nullable caches;
@property(nonatomic , assign) CGFloat value;
@property(nonatomic , assign) BOOL seeking;

- (void)setValue:(CGFloat)value animated:(BOOL)animated;
- (void)addTarget:(nullable id)target action:(SEL _Nonnull )action forControlEvents:(UIControlEvents)controlEvents;

@end
