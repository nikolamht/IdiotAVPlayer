//
//  IdiotPlayer.h
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/31.
//  Copyright © 2017年 mht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DownLoader.h"

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

typedef NS_ENUM(NSInteger, IdiotRemoteControlState) {
    IdiotRemoteControlStatePlay = 0,
    IdiotRemoteControlStatePause,
    IdiotRemoteControlStatePre,
    IdiotRemoteControlStateNext
};

typedef NS_ENUM(NSInteger, IdiotControlStyle) {
    IdiotControlStyleEmbedded = 0,
    IdiotControlStyleScreen //选择此项时 playerLayer = nil
};

@protocol IdiotPlayerDelegate <NSObject>

@optional

- (void)didIdiotStateChange:(IdiotPlayer *__weak)idiotPlayer;
- (void)didIdiotProgressChange:(IdiotPlayer *__weak)idiotPlayer;
- (void)didIdiotloadedTimeRangesChange:(IdiotPlayer *__weak)idiotPlayer;
- (void)didIdiotCacheProgressChange:(IdiotPlayer *__weak)idiotPlayer caches:(NSArray *)cacheList;

- (void)idiotAppWillResignActive:(IdiotPlayer *__weak)idiotPlayer;
- (void)idiotAppDidEnterBackground:(IdiotPlayer *__weak)idiotPlayer;
- (void)idiotAppWillEnterForeground:(IdiotPlayer *__weak)idiotPlayer;
- (void)idiotAppDidBecomeActive:(IdiotPlayer *__weak)idiotPlayer;
- (void)idiotAppDidInterrepted:(IdiotPlayer *__weak)idiotPlayer;
- (void)idiotAppDidInterreptionEnded:(IdiotPlayer *__weak)idiotPlayer;

- (void)idiotDurationAvailable:(IdiotPlayer *__weak)idiotPlayer;
- (void)idiotRemoteControlReceivedWithEvent:(IdiotPlayer *__weak)idiotPlayer;
@end

@interface IdiotPlayer : NSObject


@property(nonatomic , strong ,readonly) NSURL * currentUrl;
/*if IdiotControlStyleEmbedded => playerLayer = nil*/
@property(nonatomic , strong ,readonly) AVPlayerLayer * playerLayer;
@property(nonatomic , strong ,readonly) AVPlayer * player;
@property(nonatomic , assign ,readonly) CGFloat progress;
@property(nonatomic ,             weak) id<IdiotPlayerDelegate> delegate;
@property(nonatomic ,           assign) CGFloat duration;

@property(nonatomic , assign ,readonly) IdiotPlayerState playerState;
@property(nonatomic , assign ,readonly) IdiotRemoteControlState remoteControlState;
@property(nonatomic ,           assign) IdiotControlStyle controlStyle;

+ (instancetype)sharedInstance;

- (void)playWithUrl:(NSString *)url;

- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(CGFloat)time;
- (NSString *)formatTime:(CGFloat)time;
- (double)currentTime;

@end

extern NSString *const IdiotRemoteControlEventNotification;
