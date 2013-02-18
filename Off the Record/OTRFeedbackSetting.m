//
//  OTRFeedbackSetting.m
//  Off the Record
//
//  Created by David on 11/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRFeedbackSetting.h"
#import "OTRConstants.h"
#ifdef USERVOICE_ENABLED
#import "OTRSecrets.h"
#endif

@implementation OTRFeedbackSetting
@synthesize delegate;


- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription
{
    if (self = [super initWithTitle:newTitle description:newDescription])
    {
        self.action = @selector(showView);
    }
    return self;
}

- (void) showView
{
#ifdef USERVOICE_ENABLED
    UVConfig *config = [UVConfig configWithSite:@"chatsecure.uservoice.com"
                                         andKey:USERVOICE_KEY
                                      andSecret:USERVOICE_SECRET];
    //config.customFields = @{@"device_model": [[UIDevice currentDevice] model],@"ios_version":[[UIDevice currentDevice] systemVersion],@"chatsecure_version":[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"]};
    
    [self.delegate presentUserVoiceWithConfig:config];
#endif
}



@end
