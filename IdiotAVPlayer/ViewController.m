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
    
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
                    error:nil];
    
    myPlayer = [[IdiotPlayer alloc] initWithUrl:@"http://58.222.46.85/v.cctv.com/flash/mp4video6/TMS/2011/01/05/cf752b1c12ce452b3040cab2f90bc265_h264818000nero_aac32-1.mp4"];
    myPlayer.delegate = self;
    AVPlayerLayer * playerLayer = [AVPlayerLayer playerLayerWithPlayer:myPlayer.player];
    playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:playerLayer];
    
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
    
    
    
//    NSURL * url = [NSURL URLWithString:@"idiot://58.222.46.85/v.cctv.com/flash/mp4video6/TMS/2011/01/05/cf752b1c12ce452b3040cab2f90bc265_h264818000nero_aac32-1.mp4"];
//    
//    NSFileHandle * read = [NSFileHandle fileHandleForReadingAtPath:[[[FileManager getCacheDirectoryWithUrl:url] stringByAppendingString:@"/"] stringByAppendingString:@"0-18584541.idiot"]];
//    //1
//    [read seekToFileOffset:10000];
//    
//    NSString * path = [FileManager createSliceWithUrl:url sliceName:@"10000-18584541"];
//    
//    NSFileHandle * write = [FileManager fileHandleForWritingAtPath:path];
//    
//    [write writeData:[read readDataOfLength:1000000]];
//    
//    [write synchronizeFile];
//    [write closeFile];
//    //2
//    [read seekToFileOffset:2000000];
//    
//    NSString * path2 = [FileManager createSliceWithUrl:url sliceName:@"2000000-18584541"];
//    
//    NSFileHandle * write2 = [FileManager fileHandleForWritingAtPath:path2];
//    
//    [write2 writeData:[read readDataOfLength:4000000]];
//    
//    [write2 synchronizeFile];
//    [write2 closeFile];
//    
//    [read closeFile];
    
}

- (void)sliderValueChanged:(UISlider *)slyder{
    [myPlayer seekToTime:slyder.value*myPlayer.duration];
}

#pragma mark - IdiotPlayerDelegate

- (void)didIdiotStateChange:(IdiotPlayer *__weak)idiotPlayer{
    NSLog(@"playerState %zd",idiotPlayer.playerState);
}

- (void)didIdiotProgressChange:(IdiotPlayer *__weak)idiotPlayer{
    [slider setValue:idiotPlayer.progress animated:YES];
    
    NSLog(@"progress %f",idiotPlayer.progress);
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
