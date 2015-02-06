//
//  OTRAudioSessionManager.m
//  ChatSecure
//
//  Created by David Chiles on 1/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioSessionManager.h"

@import AVFoundation;

@interface OTRAudioSessionManager () <AVAudioPlayerDelegate, AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVAudioRecorder *currentRecorder;
@property (nonatomic, strong) AVAudioPlayer *currentPlayer;

@end

@implementation OTRAudioSessionManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    return [self.currentPlayer isPlaying];
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
    [self.currentPlayer stop];
    self.currentPlayer = nil;
    [self deactivateSession:nil];
    
}

- (NSTimeInterval)currentTimePlayTime
{
    if (self.currentPlayer) {
        return [self.currentPlayer currentTime];
    }
    return 0;
}

- (NSTimeInterval)durationPlayTime
{
    if (self.currentPlayer) {
        return [self.currentPlayer duration];
    }
    return 0;
}

- (NSURL *)currentPlayerURL
{
    return self.currentPlayer.url;
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

- (AVAudioPlayer *)audioPlayerWithURL:(NSURL *)url error:(NSError **)error
{
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:error];
    audioPlayer.delegate = self;
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

#pragma - mark AVAudioPlayerDelegate Methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if ([player isEqual:self.currentPlayer]) {
        if ([self.delegate respondsToSelector:@selector(audioSession:didFinishSuccefully:)]) {
            [self.delegate audioSession:self didFinishSuccefully:flag];
        }
    }
    
    [self.currentRecorder stop];
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
