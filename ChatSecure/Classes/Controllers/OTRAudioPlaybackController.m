//
//  OTRAudioPlaybackController.m
//  ChatSecure
//
//  Created by David Chiles on 2/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioPlaybackController.h"
#import "OTRAudioControlsView.h"
#import "OTRAudioSessionManager.h"
#import "OTRPlayPauseProgressView.h"
#import "OTRAudioItem.h"

@import AVFoundation;

@interface OTRAudioPlaybackController () <OTRAudioSessionManagerDelegate>

@property (nonatomic, strong) OTRAudioControlsView *audioControlsView;
@property (nonatomic, strong) OTRAudioSessionManager *audioSessionManager;

@property (nonatomic, strong) NSTimer *labelTimer;

@property (nonatomic) NSTimeInterval duration;

@end

@implementation OTRAudioPlaybackController

- (OTRAudioSessionManager *)audioSessionManager
{
    if (!_audioSessionManager) {
        _audioSessionManager = [[OTRAudioSessionManager alloc] init];
        _audioSessionManager.delegate = self;
    }
    return _audioSessionManager;
}

#pragma - mark Private Methods

- (void)updateTimeLabel
{
    NSTimeInterval currentTime = ceil([self.audioSessionManager currentTimePlayTime]);
    [self.audioControlsView setTime:currentTime];
}

- (void)playURL:(NSURL *)url withView:(OTRAudioControlsView *)controlsView error:(NSError **)error;
{
    self.audioControlsView = controlsView;
    AVAsset *asset = [AVAsset assetWithURL:url];
    self.duration = CMTimeGetSeconds(asset.duration);
    self.audioControlsView.playPuaseProgressView.status = OTRPlayPauseProgressViewStatusPause;
    error = nil;
    [self.audioSessionManager playAudioWithURL:url error:error];
    [self.audioControlsView.playPuaseProgressView startProgressCircleWithDuration:self.duration];
    self.audioControlsView.playPuaseProgressView.status = OTRPlayPauseProgressViewStatusPause;
    [self.audioControlsView setTime:0];
    
    [self startLabelTimer];
}

- (void)startLabelTimer
{
    self.labelTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                       target:self
                                                     selector:@selector(updateTimeLabel)
                                                     userInfo:nil
                                                      repeats:YES];
}

#pragma - mark Public Methods

- (void)playAudioItem:(OTRAudioItem *)audioItem withView:(OTRAudioControlsView *)controlsView error:(NSError **)error
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:audioItem.filename];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    
    _currentAudioItem = audioItem;
    
    [self playURL:fileURL withView:controlsView error:error];
}

- (void)pauseCurrentlyPlaying
{
    [self.audioSessionManager pausePlaying];
    [self.audioControlsView.playPuaseProgressView pauseAnimation];
    self.audioControlsView.playPuaseProgressView.status = OTRPlayPauseProgressViewStatusPlay;
    [self.labelTimer invalidate];
    self.labelTimer = nil;
    [self updateTimeLabel];
    
}

- (void)resumeCurrentlyPlaying
{
    [self updateTimeLabel];
    [self.audioSessionManager resumePlaying];
    [self.audioControlsView.playPuaseProgressView resumeAnimation];
    self.audioControlsView.playPuaseProgressView.status = OTRPlayPauseProgressViewStatusPause;
    [self startLabelTimer];
}

- (void)stopCurrentlyPlaying
{
    [self.audioSessionManager stopPlaying];
    self.audioControlsView.playPuaseProgressView.status = OTRPlayPauseProgressViewStatusPlay;
    [self.audioControlsView.playPuaseProgressView removeProgressCircle];
    [self.labelTimer invalidate];
    self.labelTimer = nil;
    [self.audioControlsView setTime:self.currentAudioItem.timeLength];
    _currentAudioItem = nil;
}

- (NSURL *)currentlyPlayingURL
{
    return [self.audioSessionManager currentPlayerURL];
}

- (BOOL)isPlaying
{
    return [self.audioSessionManager isPlaying];
}

#pragma - mark OTRAudioSessionManagerDelegate Methods

- (void)audioSession:(OTRAudioSessionManager *)audioSessionManager didFinishSuccefully:(BOOL)success
{
    self.audioControlsView.playPuaseProgressView.status = OTRPlayPauseProgressViewStatusPlay;
    [self.audioControlsView.playPuaseProgressView removeProgressCircle];
    [self.labelTimer invalidate];
    [self.audioControlsView setTime:self.currentAudioItem.timeLength];
    _currentAudioItem = nil;
}

@end
