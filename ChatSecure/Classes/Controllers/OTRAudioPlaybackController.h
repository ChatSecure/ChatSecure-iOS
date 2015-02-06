//
//  OTRAudioPlaybackController.h
//  ChatSecure
//
//  Created by David Chiles on 2/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@import UIKit;
@class OTRAudioControlsView, OTRAudioItem;

@interface OTRAudioPlaybackController : NSObject

@property (nonatomic, strong, readonly) OTRAudioItem *currentAudioItem;

- (void)playAudioItem:(OTRAudioItem *)audioItem withView:(OTRAudioControlsView *)controlsView error:(NSError **)error;

- (void)pauseCurrentlyPlaying;
- (void)resumeCurrentlyPlaying;
- (void)stopCurrentlyPlaying;
- (BOOL)isPlaying;


@end
