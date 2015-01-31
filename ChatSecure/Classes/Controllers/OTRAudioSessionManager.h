//
//  OTRAudioSessionManager.h
//  ChatSecure
//
//  Created by David Chiles on 1/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRAudioSessionManager : NSObject

@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, readonly) BOOL isPlaying;

- (void)playAudioWithURL:(NSURL *)url error:(NSError **)error;
- (void)pausePlaying;
- (void)resumePlaying;
- (void)stopPlaying;
- (NSTimeInterval)currentTimePlayTime;
- (NSTimeInterval)durationPlayTime;
- (NSURL *)currentPlayerURL;

- (void)recordAudioToURL:(NSURL *)url error:(NSError **)error;
- (void)stopRecording;
- (NSTimeInterval)currentTimeRecordTime;
- (NSURL *)currentRecorderURL;

@end
