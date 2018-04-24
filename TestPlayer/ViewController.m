//
//  ViewController.m
//  TestPlayer
//
//  Created by jft0m on 2018/4/20.
//  Copyright © 2018年 jft0m. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureAudioDataOutputSampleBufferDelegate>
@property (weak, nonatomic) IBOutlet UIView *videoPlayerView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;


@property (nonatomic) dispatch_queue_t cameraSeeionQueue;

@property (weak, nonatomic) IBOutlet UIView *capturerView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *inputCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;

@property (nonatomic, strong) AVCaptureDevice *microphone;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, assign) BOOL isPlaying;

@property (nonatomic, assign) long audioCategoryIndex;
@end

@implementation ViewController
#pragma mark Camera

- (void)setupCamera {
    NSLog(@"will setupCamera ");
    if (_captureSession) return;
    
    _inputCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    _inputCamera = devices.firstObject;
    
    if (!_inputCamera) {
        return;
    }
    // Create the capture session
    _captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    
    // Add the video input
    NSError *error = nil;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
    if ([_captureSession canAddInput:_videoInput])
    {
        [_captureSession addInput:_videoInput];
    }
    
    _microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:_microphone error:nil];
    if ([_captureSession canAddInput:_audioInput])
    {
        [_captureSession addInput:_audioInput];
    }
    
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    if ([_captureSession canAddOutput:_audioOutput])
    {
        [_captureSession addOutput:_audioOutput];
    }
    else
    {
        NSLog(@"Couldn't add audio output");
    }
    [_audioOutput setSampleBufferDelegate:self queue:self.cameraSeeionQueue];
    
    [_captureSession commitConfiguration];
    self.previewLayer.session = _captureSession;
    NSLog(@"did setupCamera ");
}

- (void)clearCamera {
    NSLog(@"will clearCamera ");
    _inputCamera = nil;
    _captureSession = nil;
    _videoInput = nil;
    
    _audioInput = nil;
    _microphone = nil;
    NSLog(@"did clearCamera ");
}

- (void)stopCameraCapture;
{
    NSLog(@"will stopCameraCapture ");
    if ([_captureSession isRunning])
    {
        [_captureSession stopRunning];
    }
    NSLog(@"did stopCameraCapture ");
}

- (void)startCameraCapture {
    NSLog(@"will startCameraCapture ");
    if (![_captureSession isRunning])
    {
        [_captureSession startRunning];
    };
    NSLog(@"did startCameraCapture ");
}


#pragma mark - life

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cameraSeeionQueue = dispatch_queue_create("com.jft.audia.queue", DISPATCH_QUEUE_SERIAL);
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] init];
    _previewLayer.frame = self.capturerView.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.capturerView.layer addSublayer:_previewLayer];
    
    [self setupCamera];
    
    self.isPlaying = NO;
    self.player = [AVPlayer new];
    
    self.playerLayer = [AVPlayerLayer layer];
    self.playerLayer.frame = self.videoPlayerView.bounds;
    [self.videoPlayerView.layer addSublayer:self.playerLayer];
    self.playerLayer.player = self.player;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:nil];
    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];

//    PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[@"D6DDC319-5911-4C95-A0CD-1A3B46DFFD37/L0/001"] options:nil];
    PHAsset *asset = result.firstObject;
    if (asset) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            [self.player replaceCurrentItemWithPlayerItem:playerItem];
        }];
    }
    
    [self.player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruption:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)audioSessionInterruption:(NSNotification *)noti {
    NSLog(@"%@", noti);
}

- (void)didPlayToEndTime:(NSNotification *)notification {
    if (notification.object == self.player.currentItem) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"====== replay");
            [self.player.currentItem seekToTime:kCMTimeZero];
            [self.player play];
        });
    }
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(AVPlayer *)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
//    NSLog(@"%@", change);
    if ([keyPath isEqualToString:@"timeControlStatus"]) {
        NSLog(@"timeControlStatus");
        switch ([(NSNumber *)change[NSKeyValueChangeNewKey] integerValue]) {
            case AVPlayerTimeControlStatusPaused:
                NSLog(@"AVPlayerTimeControlStatusPaused");
                break;
            case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:
                NSLog(@"AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate");
                break;
            case AVPlayerTimeControlStatusPlaying:
                NSLog(@"AVPlayerTimeControlStatusPlaying");
                break;
            default:
                break;
        }
    }
}

- (IBAction)changePlayStatus:(UIButton *)sender {
    NSLog(@"!!!!!!!! Click");
    if (self.isPlaying) {
        [sender setTitle:@"播放" forState:UIControlStateNormal];
        NSLog(@"==== pause");
        [self.player pause];
        self.isPlaying = NO;
        dispatch_async(self.cameraSeeionQueue, ^{
            NSLog(@"will setupCamera ");
            [self setupCamera];
            NSLog(@"did setupCamera ");
            NSLog(@"===== ");
            NSLog(@"will startCameraCapture ");
            [self startCameraCapture];
            NSLog(@"did startCameraCapture ");
        });
        
    } else {
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            dispatch_async(self.cameraSeeionQueue, ^{
                [self stopCameraCapture];
                [self clearCamera];
                NSLog(@"will setCategory ");
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:nil];
                NSLog(@"did setCategory ");
            });
            [sender setTitle:@"暂停" forState:UIControlStateNormal];
            NSLog(@"==== play");
            [self.player play];
            self.isPlaying = YES;
        } else {
            NSLog(@"==== play ===== error!!!!");
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    return;
}

@end
