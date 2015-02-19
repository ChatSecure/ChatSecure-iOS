//
//  OTRAudioSessionManager.m
//  ChatSecure
//
//  Created by David Chiles on 1/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAudioSessionManager.h"
#import "EZAudio.h"

@import AVFoundation;

@interface OTRAudioSessionManager () <AVAudioPlayerDelegate, EZMicrophoneDelegate>

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVAudioPlayer *currentPlayer;

@property (nonatomic, strong) EZRecorder *recorder;
@property (nonatomic, strong) EZMicrophone *microphone;

@property (nonatomic, strong) NSDate *startRecordingDate;

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
    if (self.microphone) {
        return self.microphone.microphoneOn;
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
    
    self.microphone = [EZMicrophone sharedMicrophone];
    self.microphone.microphoneDelegate = self;
    self.recorder = [EZRecorder recorderWithDestinationURL:url
                                              sourceFormat:self.microphone.audioStreamBasicDescription
                                       destinationFileType:EZRecorderFileTypeM4A];
    
    [self.microphone startFetchingAudio];
    self.startRecordingDate = [NSDate date];
}

- (void)stopRecording
{
    [self.microphone stopFetchingAudio];
    self.microphone = nil;
    [self.recorder closeAudioFile];
    self.recorder = nil;
    self.startRecordingDate = nil;
    [self deactivateSession:nil];
}

- (NSTimeInterval)currentTimeRecordTime
{
    if (self.startRecordingDate) {
        return [[NSDate date] timeIntervalSinceDate:self.startRecordingDate];
    }
    return 0;
}

- (NSURL *)currentRecorderURL
{
    return [self.recorder url];
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

#pragma - mark EZMicrophoneDelegateMethods

- (void)microphone:(EZMicrophone *)microphone hasBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    [self.recorder appendDataFromBufferList:bufferList withBufferSize:bufferSize];
}

- (void)microphone:(EZMicrophone *)microphone hasAudioReceived:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    if ([self.delegate respondsToSelector:@selector(audioSession:hasAudioReceived:withBufferSize:withNumberOfChannels:)]) {
        [self.delegate audioSession:self hasAudioReceived:buffer withBufferSize:bufferSize withNumberOfChannels:numberOfChannels];
    }
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
