## IdiotAVPlayer
使用AVPlayer实现的可以分片缓存音视频的库
后面会补上使用方法（其实大家看代码就能用起来），也会上传pod
如果大家发现bug或者有好的建议请联系我1335304336@qq.com 邮箱号就是qq号。
![效果图](https://github.com/nikolamht/IdiotAVPlayer/blob/master/preview/effect.png?raw=true)
[这里有视频效果](http://t.cn/RQlUsyi?m=4198628275397043&u=3170976717)
## 简单使用

IdiotPlayer * myPlayer = [[IdiotPlayer alloc] init];
myPlayer.controlStyle = IdiotControlStyleScreen;
myPlayer.delegate = self;
[myPlayer playWithUrl:@"http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4"];
if (myPlayer.playerLayer) {
myPlayer.playerLayer.frame = self.view.bounds;
[self.view.layer addSublayer:myPlayer.playerLayer];
}
[myPlayer play];
## Appdelegate设置

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
[IdiotDownLoader share];
return YES;
}
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
completionHandler:(void (^)())completionHandler
{
[IdiotDownLoader share].backgroundSessionCompletionHandler = completionHandler;
}
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
[[NSNotificationCenter defaultCenter]postNotificationName:IdiotRemoteControlEventNotification object:event];
}
- (void)applicationDidEnterBackground:(UIApplication *)application {
[application beginReceivingRemoteControlEvents];
[self becomeFirstResponder];
}

## 更多
- -(void)didIdiotStateChange:(IdiotPlayer *__weak)idiotPlayer;
- -(void)didIdiotProgressChange:(IdiotPlayer *__weak)idiotPlayer;
- -(void)didIdiotloadedTimeRangesChange:(IdiotPlayer *__weak)idiotPlayer;
- -(void)didIdiotCacheProgressChange:(IdiotPlayer *__weak)idiotPlayer caches:(NSArray *)cacheList;

- -(void)idiotAppWillResignActive:(IdiotPlayer *__weak)idiotPlayer;
- -(void)idiotAppDidEnterBackground:(IdiotPlayer *__weak)idiotPlayer;
- -(void)idiotAppWillEnterForeground:(IdiotPlayer *__weak)idiotPlayer;
- -(void)idiotAppDidBecomeActive:(IdiotPlayer *__weak)idiotPlayer;
- -(void)idiotAppDidInterrepted:(IdiotPlayer *__weak)idiotPlayer;
- -(void)idiotAppDidInterreptionEnded:(IdiotPlayer *__weak)idiotPlayer;

- -(void)idiotDurationAvailable:(IdiotPlayer *__weak)idiotPlayer;
- -(void)idiotRemoteControlReceivedWithEvent:(IdiotPlayer *__weak)idiotPlayer;
## 原理图
![原理图](https://upload-images.jianshu.io/upload_images/9724987-5e2ca99d7359df7e.png)



<<<<<<< HEAD
=======
![效果图](https://github.com/nikolamht/IdiotAVPlayer/blob/master/preview/effect.png?raw=true)

视频地址http://t.cn/RQlUsyi?m=4198628275397043&u=3170976717
>>>>>>> origin/master
