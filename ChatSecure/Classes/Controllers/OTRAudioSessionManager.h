//
//  OTRAudioSessionManager.h
//  ChatSecure
//
//  Created by David Chiles on 1/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTRAudioSessionManager;

@protocol OTRAudioSessionManagerDelegate <NSObject>

- (void)audioSession:(OTRAudioSessionManager *)audioSessionManager didFinishWithError:(NSError *)error;

@end

@interface OTRAudioSessionManager : NSObject

@property (nonatomic, readonly) BOOL isPlaying;

@property (nonatomic, weak) id<OTRAudioSessionManagerDelegate> delegate;

- (void)playAudioWithURL:(NSURL *)url error:(NSError **)error;
- (void)pausePlaying;
- (void)resumePlaying;
- (void)stopPlaying;
- (NSTimeInterval)currentTimePlayTime;
- (NSTimeInterval)durationPlayTime;
- (NSURL *)currentPlayerURL;
- (BOOL)isPlaying;

- (void)recordAudioToURL:(NSURL *)url error:(NSError **)error;
- (void)stopRecording;
- (NSTimeInterval)currentTimeRecordTime;
- (NSURL *)currentRecorderURL;
- (BOOL)isRecording;

@end
