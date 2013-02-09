//
//  OTRFeedbackSetting.h
//  Off the Record
//
//  Created by David on 11/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSetting.h"
#import "UserVoice.h"

@protocol OTRFeedbackSettingDelegate <OTRSettingDelegate>
@required
- (void) presentUserVoiceWithConfig:(UVConfig*)config;
@end

@interface OTRFeedbackSetting : OTRSetting

@property (nonatomic, weak) id <OTRFeedbackSettingDelegate> delegate;

- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription;

- (void) showView;


@end
