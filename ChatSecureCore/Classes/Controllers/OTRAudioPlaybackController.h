//
//  OTRAudioPlaybackController.h
//  ChatSecure
//
//  Created by David Chiles on 2/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;

@import UIKit;
@class OTRAudioControlsView, OTRAudioItem;

@interface OTRAudioPlaybackController : NSObject

@property (nonatomic, strong, readonly) OTRAudioItem *currentAudioItem;
@property (nonatomic, weak, readonly) OTRAudioControlsView *currentAudioControlsView;

- (BOOL)playAudioItem:(OTRAudioItem *)audioItem buddyUniqueId:(NSString *)buddyUniqueId error:(NSError **)error;

- (void)attachAudioControlsView:(OTRAudioControlsView *)audioControlsView;

- (void)pauseCurrentlyPlaying;
- (void)resumeCurrentlyPlaying;
- (void)stopCurrentlyPlaying;
- (BOOL)isPlaying;


@end
