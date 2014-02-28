//
//  OTRFeedbackSetting.m
//  Off the Record
//
//  Created by David on 11/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRFeedbackSetting.h"
#import "OTRConstants.h"
#import "OTRSecrets.h"

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
    UVConfig *config = [UVConfig configWithSite:@"chatsecure.uservoice.com"
                                         andKey:kOTRUservoiceKey
                                      andSecret:kOTRUservoiceSecret];    
    [self.delegate presentUserVoiceWithConfig:config];
}



@end
