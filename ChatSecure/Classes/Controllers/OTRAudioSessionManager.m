//
//  OTRAudioSessionManager.m
//  ChatSecure
//
//  Created by David Chiles on 1/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioSessionManager.h"
@import KVOController;

@import AVFoundation;

@interface OTRAudioSessionManager () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *currentRecorder;
@property (nonatomic, strong) AVPlayer *currentPlayer;

@property (nonatomic, strong) NSTimer *recordDecibelTimer;

@end

@implementation OTRAudioSessionManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma - mark Setters && Getters

- (BOOL)isRecording
{
    if (self.currentRecorder) {
        return self.currentRecorder.isRecording;
    }
    
    return NO;
}

- (BOOL)isPlaying
{
    if (self.currentPlayer.rate > 0 && !self.currentPlayer.error) {
        return YES;
    }
    return NO;
}

#pragma - mark Public Methods

////// Playing //////
- (BOOL)playAudioWithURL:(NSURL *)url error:(NSError **)error
{
    [self stopPlaying];
    [self stopRecording];
    error = nil;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:error];
    if (error) {
        return NO;
    }
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeSpokenAudio error:error];
    if (error) {
        return NO;
    }
    
    error = nil;
    self.currentPlayer = [self audioPlayerWithURL:url error:error];
    if (error) {
        return NO;
    }
    
    [self.currentPlayer play];
    
    return YES;
}

- (void)pausePlaying
{
    [self.currentPlayer pause];
}

- (void)resumePlaying
{
    [self.currentPlayer play];
}

- (void)stopPlaying
{
    [self.currentPlayer pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.KVOController unobserve:self.currentPlayer];
    self.currentPlayer = nil;
    [self deactivateSession:nil];
    
}

- (NSTimeInterval)currentTimePlayTime
{
    if (self.currentPlayer) {
        CMTime time = [self.currentPlayer currentTime];
        return CMTimeGetSeconds(time);
    }
    return 0;
}

- (NSTimeInterval)durationPlayTime
{
    if (self.currentPlayer) {
        return CMTimeGetSeconds([self.currentPlayer currentItem].duration);
    }
    return 0;
}

- (NSURL *)currentPlayerURL
{
    if ([self.currentPlayer.currentItem.asset isKindOfClass:AVURLAsset.class]) {
        return ((AVURLAsset *)self.currentPlayer.currentItem.asset).URL;
    }
    return nil;
}

////// Recording //////
- (BOOL)recordAudioToURL:(NSURL *)url error:(NSError **)error
{
    [self stopRecording];
    [self stopPlaying];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:error];
    if (error) {
        return NO;
    }
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeSpokenAudio error:error];
    if (error) {
        return NO;
    }
    
    self.currentRecorder = [self audioRecorderWithURL:url error:error];
    
    if (error) {
        return NO;
    }
    
    self.currentRecorder.meteringEnabled = YES;
    self.recordDecibelTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(updateDecibelRecording:) userInfo:nil repeats:YES];
    
    [self.currentRecorder record];
    
    return YES;
}

- (void)stopRecording
{
    [self.recordDecibelTimer invalidate];
    self.recordDecibelTimer = nil;
    [self.currentRecorder stop];
    self.currentRecorder = nil;
    [self deactivateSession:nil];
    
}

- (void)updateDecibelRecording:(id)sender
{
    [self.currentRecorder updateMeters];
    double decibles = [self.currentRecorder averagePowerForChannel:0];
    if ([self.delegate respondsToSelector:@selector(audioSession:didUpdateRecordingDecibel:)]) {
        [self.delegate audioSession:self didUpdateRecordingDecibel:decibles];
    }
}

- (NSTimeInterval)currentTimeRecordTime
{
    if (self.currentRecorder) {
        return self.currentRecorder.currentTime;
    }
    return 0;
}

- (NSURL *)currentRecorderURL
{
    return self.currentRecorder.url;
}

#pragma - mark Private Methods

- (BOOL)deactivateSession:(NSError **)error
{
    return [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:error];
}

- (AVPlayer *)audioPlayerWithURL:(NSURL *)url error:(NSError **)error
{
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:url];
    AVPlayer *audioPlayer = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidErrorPlaying:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:playerItem];
    
    __weak typeof(self)weakSelf = self;
    [self.KVOController observe:audioPlayer keyPath:NSStringFromSelector(@selector(rate)) options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if ([object isEqual:strongSelf.currentPlayer]) {
            if (strongSelf.currentPlayer.rate && [strongSelf.delegate respondsToSelector:@selector(audioSessionDidStartPlaying:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.delegate audioSessionDidStartPlaying:strongSelf];
                });
            }
        }
        
    }];
    
    return audioPlayer;
}

- (AVAudioRecorder *)audioRecorderWithURL:(NSURL *)url error:(NSError **)error
{
    NSDictionary *settings = [[self class] defaultRecordingSettings];
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:error];
    recorder.delegate = self;
    return recorder;
}

#pragma - mark AVAudioRecorderDelegate Methods

#pragma - mark AVAudioPlayerDelegate Notifcation

- (void)itemDidFinishPlaying:(NSNotification *)notification
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        AVPlayerItem *playerItem = notification.object;
        [strongSelf playerItem:playerItem finishedPlayingWithError:nil];
    });
}

- (void)itemDidErrorPlaying:(NSNotification *)notification
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        AVPlayerItem *playerItem = notification.object;
        [strongSelf playerItem:playerItem finishedPlayingWithError:playerItem.error];
    });
}

- (void)playerItem:(AVPlayerItem *)playerItem finishedPlayingWithError:(NSError *)error
{
    if ([playerItem isEqual:self.currentPlayer.currentItem]) {
        if ([self.delegate respondsToSelector:@selector(audioSession:didFinishWithError:)]) {
            [self.delegate audioSession:self didFinishWithError:error];
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.KVOController unobserve:self.currentPlayer];
    self.currentPlayer = nil;
    [self deactivateSession:nil];
}

#pragma - mark Class Methods

+ (NSDictionary *)defaultRecordingSettings
{
    return @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
             AVSampleRateKey: @(16000),
             AVNumberOfChannelsKey: @(1),
             AVEncoderBitRatePerChannelKey: @(16000)};
}
@end
