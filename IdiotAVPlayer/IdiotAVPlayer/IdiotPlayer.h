//
//  IdiotPlayer.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/31.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IdiotPlayer;

typedef NS_ENUM(NSInteger, IdiotPlayerState) {
    IdiotPlayerStateWaiting = 0,
    IdiotPlayerStateReady,
    IdiotPlayerStatePlaying,
    IdiotPlayerStatePaused,
    IdiotPlayerStateStopped,
    IdiotPlayerStateBuffering,
    IdiotPlayerStateError
};

@protocol IdiotPlayerDelegate <NSObject>

@optional

- (void)didIdiotStateChange:(IdiotPlayer *__weak)idiotPlayer;
- (void)didIdiotProgressChange:(IdiotPlayer *__weak)idiotPlayer;
- (void)didIdiotloadedTimeRangesChange:(IdiotPlayer *__weak)idiotPlayer;
- (void)didIdiotCacheProgressChange:(IdiotPlayer *__weak)idiotPlayer caches:(NSArray *)cacheList;

@end

@interface IdiotPlayer : NSObject

@property(nonatomic , strong ,readonly) NSURL * currentUrl;
@property(nonatomic , strong ,readonly) AVPlayer * player;
@property(nonatomic , assign ,readonly) IdiotPlayerState playerState;
@property(nonatomic , assign ,readonly) CGFloat progress;
@property(nonatomic , weak) id<IdiotPlayerDelegate> delegate;
@property(nonatomic , assign) CGFloat duration;

- (instancetype)initWithUrl:(NSString *)url;
- (void)seekToTime:(CGFloat)time;

@end
