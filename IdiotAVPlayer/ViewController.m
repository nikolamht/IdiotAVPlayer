//
//  ViewController.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>

#import "ViewController.h"
#import "DownLoader.h"
#import "ResourceLoader.h"
#import "IdiotPlayer.h"
#import "IdiotSlider.h"
#import "FileManager.h"


@interface ViewController () <IdiotPlayerDelegate>
{
    IdiotPlayer * myPlayer;
    IdiotSlider * slider;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    myPlayer = [[IdiotPlayer alloc] init];
    myPlayer.controlStyle = IdiotControlStyleScreen;
    myPlayer.delegate = self;
    [myPlayer playWithUrl:@"http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4"];
    
    if (myPlayer.playerLayer) {
        myPlayer.playerLayer.frame = self.view.bounds;
        [self.view.layer addSublayer:myPlayer.playerLayer];
    }
    
    [myPlayer play];
    
    slider = [[IdiotSlider alloc] initWithFrame:CGRectMake(15, 500, self.view.bounds.size.width-30, 15)];
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventTouchUpInside];
    [slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:slider];
    
}

- (void)sliderValueChanged:(UISlider *)slyder {
    [myPlayer seekToTime:slyder.value*myPlayer.duration];
}

- (void)sliderTouchDown:(UISlider *)slyder {
    slider.seeking = YES;
}

#pragma mark - IdiotPlayerDelegate

- (void)didIdiotStateChange:(IdiotPlayer *__weak)idiotPlayer{
    
    if (idiotPlayer.playerState == IdiotPlayerStatePlaying) {
        slider.seeking = NO;
    }
    
    DLogDebug(@"playerState %zd",idiotPlayer.playerState);
}

- (void)didIdiotProgressChange:(IdiotPlayer *__weak)idiotPlayer{
    
    if (slider.seeking) {
        return;
    }
    
    [slider setValue:idiotPlayer.progress animated:YES];
    DLogDebug(@"progress %f",idiotPlayer.progress);
}

- (void)didIdiotloadedTimeRangesChange:(IdiotPlayer *__weak)idiotPlayer{
    
}

- (void)didIdiotCacheProgressChange:(IdiotPlayer *__weak)idiotPlayer caches:(NSArray *)cacheList
{
    [slider setCaches:cacheList];
}

- (void)idiotAppDidEnterBackground:(IdiotPlayer *__weak)idiotPlayer
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"IdiotPlayer" forKey:MPMediaItemPropertyTitle];
    [dict setObject:@"TED-talks"  forKey:MPMediaItemPropertyArtist];
    [dict setObject:[NSNumber numberWithFloat:idiotPlayer.duration]  forKey:MPMediaItemPropertyPlaybackDuration];
    [dict setObject:[NSNumber numberWithFloat:[idiotPlayer currentTime]]  forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
}

- (void)idiotRemoteControlReceivedWithEvent:(IdiotPlayer *__weak)idiotPlayer{
    switch (idiotPlayer.remoteControlState) {
        case IdiotRemoteControlStatePlay:
        {
            DLogInfo(@"播放");
            [idiotPlayer play];
        } break;
        case IdiotRemoteControlStatePause:
        {
            DLogInfo(@"暂停");
            [idiotPlayer pause];
        } break;
        case IdiotRemoteControlStatePre:
        {
            DLogInfo(@"上一首");
        } break;
        case IdiotRemoteControlStateNext:
        {
            DLogInfo(@"下一首");
        } break;
            
        default:
            break;
    }
}


#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
