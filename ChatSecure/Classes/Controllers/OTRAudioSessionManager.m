//
//  OTRAudioSessionManager.m
//  ChatSecure
//
//  Created by David Chiles on 1/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioSessionManager.h"

@import AVFoundation;

@interface OTRAudioSessionManager () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVAudioRecorder *currentRecorder;
@property (nonatomic, strong) AVPlayer *currentPlayer;

@end

@implementation OTRAudioSessionManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_currentPlayer removeObserver:self forKeyPath:NSStringFromSelector(@selector(rate))];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.audioSession = [AVAudioSession sharedInstance];
        [self.audioSession setMode:AVAudioSessionModeVoiceChat error:nil];
    }
    return self;
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
- (void)playAudioWithURL:(NSURL *)url error:(NSError **)error
{
    [self stopPlaying];
    [self stopRecording];
    error = nil;
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:error];
    if (error) {
        return;
    }
    
    error = nil;
    self.currentPlayer = [self audioPlayerWithURL:url error:error];
    if (error) {
        return;
    }
    
    [self.currentPlayer play];
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
    [self.currentPlayer removeObserver:self forKeyPath:NSStringFromSelector(@selector(rate))];
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
- (void)recordAudioToURL:(NSURL *)url error:(NSError **)error
{
    [self stopRecording];
    [self stopPlaying];
    
    [self.audioSession setCategory:AVAudioSessionCategoryRecord error:error];
    if (error) {
        return;
    }
    
    self.currentRecorder = [self audioRecorderWithURL:url error:error];
    if (error) {
        return;
    }
    
    [self.currentRecorder record];
}

- (void)stopRecording
{
    [self.currentRecorder stop];
    self.currentRecorder = nil;
    [self deactivateSession:nil];
    
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

- (void)deactivateSession:(NSError **)error
{
    [self.audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:error];
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
    
    [audioPlayer addObserver:self forKeyPath:NSStringFromSelector(@selector(rate)) options:NSKeyValueObservingOptionNew context:NULL];
    
    return audioPlayer;
}

- (AVAudioRecorder *)audioRecorderWithURL:(NSURL *)url error:(NSError **)error
{
    NSDictionary *settings = [[self class] defaultRecordingSettings];
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:error];
    recorder.delegate = self;
    return recorder;
}

#pragma - mark KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(rate))]) {
        if ([object isEqual:self.currentPlayer]) {
            if (self.currentPlayer.rate && [self.delegate respondsToSelector:@selector(audioSessionDidStartPlaying:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate audioSessionDidStartPlaying:self];
                });
            }
        }
    }
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
    [self.currentPlayer removeObserver:self forKeyPath:NSStringFromSelector(@selector(rate))];
    self.currentPlayer = nil;
    [self deactivateSession:nil];
}

#pragma - mark Class Methods

+ (NSDictionary *)defaultRecordingSettings
{
    return @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
             AVSampleRateKey: @(16000),
             AVNumberOfChannelsKey: @(1)};
}
@end
