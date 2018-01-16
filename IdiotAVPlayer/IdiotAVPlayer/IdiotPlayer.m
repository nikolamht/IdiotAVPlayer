//
//  IdiotPlayer.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/31.
//  Copyright © 2017年 mht. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#import "IdiotPlayer.h"
#import "ResourceLoader.h"
#import "NSURL+IdiotURL.h"

@interface IdiotPlayer () <ResourceLoaderCacheProgressDelegate>

@property(nonatomic , strong) NSURL * currentUrl;
@property(nonatomic , strong) ResourceLoader * resourceLoader;
@property(nonatomic , strong) dispatch_queue_t queue;
@property(nonatomic , strong) AVURLAsset * playerAsset;
@property(nonatomic , strong) AVPlayerItem * playerItem;
@property(nonatomic , strong) AVPlayer * player;
@property(nonatomic , assign) id timeObserver;
@property(nonatomic , assign) CGFloat progress;

@property(nonatomic , assign)IdiotPlayerState playerState;
@end

@implementation IdiotPlayer

#pragma mark -
- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (!self) { return nil; }
    _currentUrl = [NSURL URLWithString:[url copy]];
    [self setItem];
    return self;
}

- (void)setItem {
    
    _resourceLoader = [[ResourceLoader alloc] init];
    _resourceLoader.delegate = self;
    
    if (!_queue) {
        _queue = dispatch_queue_create("com.idiot.serial", DISPATCH_QUEUE_SERIAL);
    }
    
    _playerAsset = [AVURLAsset URLAssetWithURL:[_currentUrl idiotSchemeURL] options:nil];
    [_playerAsset.resourceLoader setDelegate:_resourceLoader queue:_queue];
    
    _playerItem = [AVPlayerItem playerItemWithAsset:_playerAsset];
    
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    
    [self addObserver];
}

- (void)addObserver {
    
    _playerState = IdiotPlayerStateWaiting;
    
    [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    
    //播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPlayBackEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    //即将进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    
    //进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
    
    //即将进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name: UIApplicationWillEnterForegroundNotification object:nil];
    
    //激活
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object:nil];
    
    //中断事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInterrepted:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    //播放进度
    __weak typeof(self) weakself = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        __strong typeof(weakself) strongself = weakself;
        
        CGFloat current = CMTimeGetSeconds(time);
        CGFloat total = CMTimeGetSeconds(strongself.playerItem.duration);
        
        strongself.progress = total==0?0:current/total;
        
        if (strongself.delegate&&[strongself.delegate respondsToSelector:@selector(didIdiotProgressChange:)]) {
            [strongself.delegate didIdiotProgressChange:strongself];
        }
        
    }];
    
}

#pragma mark - control
- (void)play{
    if (_player) {
        [_player play];
    }
}

- (void)pause{
    if (_player) {
        [_player pause];
    }
}

- (void)seekToTime:(CGFloat)time{
    
    [self.player pause];
    self.resourceLoader.seek = YES;
    __weak typeof(self) weakself = self;
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        __strong typeof(weakself) strongself = weakself;
        [strongself.player play];
    }];
    
}

- (CGFloat)duration{
    _duration = CMTimeGetSeconds(_playerItem.duration);
    return _duration;
}

- (double)currentTime{
    return self.player.currentTime.value/self.player.currentTime.timescale;
}

- (void)didPlayBackEnd{
    _playerState = IdiotPlayerStateStopped;
    if (_delegate&&[_delegate respondsToSelector:@selector(didIdiotStateChange:)]) {
        [_delegate didIdiotStateChange:self];
    }
}

- (void)appWillResignActive {
    DLogDebug(@"即将进入后台");
    if (_delegate&&[_delegate respondsToSelector:@selector(idiotAppWillResignActive:)]) {
        [_delegate idiotAppWillResignActive:self];
    }
}

- (void)appDidEnterBackground {
    DLogDebug(@"已经进入后台");
    if (_delegate&&[_delegate respondsToSelector:@selector(idiotAppDidEnterBackground:)]) {
        [_delegate idiotAppDidEnterBackground:self];
    }
}

- (void)appWillEnterForeground {
    DLogDebug(@"即将进入前台");
    if (_delegate&&[_delegate respondsToSelector:@selector(idiotAppWillEnterForeground:)]) {
        [_delegate idiotAppWillEnterForeground:self];
    }
}

- (void)appDidBecomeActive {
    DLogDebug(@"已经变为活动");
    if (_delegate&&[_delegate respondsToSelector:@selector(idiotAppDidBecomeActive:)]) {
        [_delegate idiotAppDidBecomeActive:self];
    }
}

- (void)appDidInterrepted:(NSNotification *)notification{
    
    if (AVAudioSessionInterruptionTypeBegan == [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue])
    {
        DLogDebug(@"打断事件");
        if (_delegate&&[_delegate respondsToSelector:@selector(idiotAppDidInterrepted:)]) {
            [_delegate idiotAppDidInterrepted:self];
        }else{
            [self pause];
        }
    } else if (AVAudioSessionInterruptionTypeEnded == [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue])
    {
        DLogDebug(@"打断事件结束");
        if (_delegate&&[_delegate respondsToSelector:@selector(idiotAppDidInterreptionEnded:)]) {
            [_delegate idiotAppDidInterreptionEnded:self];
        }else{
            [self play];
        }
    }
    
}

/*
 返回可读区域
 */
- (NSTimeInterval)availableDuration{
    NSArray * loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];//获取缓冲区域
    Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
    Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

#pragma mark - observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        
        AVPlayerItem * playerItem = (AVPlayerItem *)object;
        
        if ([keyPath isEqualToString:@"status"])//监听状态
        {
            switch (playerItem.status) {
//                case AVPlayerStatusReadyToPlay:
//                {
//                    _playerState = IdiotPlayerStateReady;
//                    if (_delegate&&[_delegate respondsToSelector:@selector(didIdiotStateChange:)]) {
//                        [_delegate didIdiotStateChange:self];
//                    }
//                    
//                } break;
                case AVPlayerStatusFailed: AVPlayerStatusUnknown:
                {
                    _playerState = IdiotPlayerStateError;
                    if (_delegate&&[_delegate respondsToSelector:@selector(didIdiotStateChange:)]) {
                        [_delegate didIdiotStateChange:self];
                    }
                    
                } break;
                default:
                    break;
            }
            
            return;
        }
        
        if ([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            
            if (_delegate&&[_delegate respondsToSelector:@selector(didIdiotloadedTimeRangesChange:)]) {
                [_delegate didIdiotloadedTimeRangesChange:self];
            }
            
            if (_playerState == IdiotPlayerStateBuffering&&_player.rate==0)
            {
                
                NSTimeInterval interval = [self availableDuration];
                
                if (interval > [self currentTime]+5.0) {//卡顿后加载完成自行播放
                    [_player play];
                    if ([_delegate respondsToSelector:@selector(didIdiotStateChange:)])
                    {
                        [_delegate didIdiotStateChange:self];
                    }
                }
            }
            
            return;
        }
        
        if ([keyPath isEqualToString:@"playbackBufferFull"])
        {
            return;
        }
        
        if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            DLogDebug(@"playbackBufferEmpty");
            _playerState = IdiotPlayerStateBuffering;
            if ([_delegate respondsToSelector:@selector(didIdiotStateChange:)])
            {
                [_delegate didIdiotStateChange:self];
            }
            return;
        }
        
        return;
    }
    
    if ([keyPath isEqualToString:@"rate"]) {
        if (self.player.rate <= 0.0) {
            _playerState = IdiotPlayerStatePaused;
            if (_delegate&&[_delegate respondsToSelector:@selector(didIdiotStateChange:)]) {
                [_delegate didIdiotStateChange:self];
            }
        }else {
            _playerState = IdiotPlayerStatePlaying;
            if (_delegate&&[_delegate respondsToSelector:@selector(didIdiotStateChange:)]) {
                [_delegate didIdiotStateChange:self];
            }
        }
        
        return;
    }
    
}

#pragma mark - ResourceLoaderCacheProgressDelegate
- (void)didCacheProgressChange:(NSArray *)cacheProgressList{
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(didIdiotCacheProgressChange:caches:)]) {
        [self.delegate didIdiotCacheProgressChange:self caches:cacheProgressList];
    }
    
}

#pragma mark - dealloc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_timeObserver) {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [_player removeObserver:self forKeyPath:@"rate"];
    [_player replaceCurrentItemWithPlayerItem:nil];
}

@end
