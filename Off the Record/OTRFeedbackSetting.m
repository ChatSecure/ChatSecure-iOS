//
//  OTRFeedbackSetting.m
//  Off the Record
//
//  Created by David on 11/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRFeedbackSetting.h"

@implementation OTRFeedbackSetting
@synthesize delegate;

- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription
{
    if (self = [super initWithTitle:newTitle description:newDescription])
    {
        __weak typeof (self) weakSelf = self;
        self.actionBlock = ^{
            [weakSelf showView];
        };
    }
    return self;
}

- (void) showView
{
    [self.delegate presentUserVoiceView];
}

@end
