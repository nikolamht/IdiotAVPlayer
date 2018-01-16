//
//  ViewController.m
//  IdiotAVPlayer
//
//  Created by 老板 on 2017/12/30.
//  Copyright © 2017年 mht. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"
#import "DownLoader.h"
#import "ResourceLoader.h"
#import "IdiotPlayer.h"
#import "IdiotSlider.h"
#import "FileManager.h"


@interface ViewController () <IdiotPlayerDelegate>
{
    IdiotPlayer * myPlayer;
    UISlider * slider;
    IdiotSlider * slider3;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    myPlayer = [[IdiotPlayer alloc] initWithUrl:@"http://121.40.229.16:8083/data//resources/course/101140/audio/step1509608551851_audio.mp3"];
    myPlayer.delegate = self;
//    AVPlayerLayer * playerLayer = [AVPlayerLayer playerLayerWithPlayer:myPlayer.player];
//    playerLayer.frame = self.view.bounds;
//    [self.view.layer addSublayer:playerLayer];
    
    [myPlayer.player play];
    
    slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 200, self.view.bounds.size.width-30, 20)];
    slider.minimumValue = 0.0;// 设置最小值
    slider.maximumValue = 1.0;// 设置最大值
    slider.value = 0 ;// 设置初始值
    slider.continuous = YES;// 设置可连续变化
    slider.minimumTrackTintColor = [UIColor greenColor]; //滑轮左边颜色，如果设置了左边的图片就不会显示
    slider.maximumTrackTintColor = [UIColor lightGrayColor]; //滑轮右边颜色，如果设置了右边的图片就不会显示
    slider.thumbTintColor = [UIColor colorWithRed:114.0/255.0 green:114.0/255.0 blue:114.0/255.0 alpha:0.5];//设置了滑轮的颜色，如果设置了滑轮的样式图片就不会显示
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:slider];
    
    slider3 = [[IdiotSlider alloc] initWithFrame:CGRectMake(15, 500, self.view.bounds.size.width-30, 5)];
    [self.view addSubview:slider3];
    
}

- (void)sliderValueChanged:(UISlider *)slyder{
    [myPlayer seekToTime:slyder.value*myPlayer.duration];
}

#pragma mark - IdiotPlayerDelegate

- (void)didIdiotStateChange:(IdiotPlayer *__weak)idiotPlayer{
    DLogDebug(@"playerState %zd",idiotPlayer.playerState);
}

- (void)didIdiotProgressChange:(IdiotPlayer *__weak)idiotPlayer{
    [slider setValue:idiotPlayer.progress animated:YES];
    DLogDebug(@"progress %f",idiotPlayer.progress);
}

- (void)didIdiotloadedTimeRangesChange:(IdiotPlayer *__weak)idiotPlayer{
    
}

- (void)didIdiotCacheProgressChange:(IdiotPlayer *__weak)idiotPlayer caches:(NSArray *)cacheList
{
    [slider3 setCaches:cacheList];
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
