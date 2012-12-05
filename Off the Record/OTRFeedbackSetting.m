//
//  OTRFeedbackSetting.m
//  Off the Record
//
//  Created by David on 11/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRFeedbackSetting.h"
#import "OTRConstants.h"

@implementation OTRFeedbackSetting
@synthesize delegate;
@synthesize mailSubject;
@synthesize mailToRecipients;


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
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController * mailComposer = [[MFMailComposeViewController alloc] init];
        [mailComposer setSubject:mailSubject];
        [mailComposer setToRecipients:mailToRecipients];
        mailComposer.mailComposeDelegate = self;
        [self.delegate presentMailViewController:mailComposer];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self.delegate dismissMailViewConntroller];
}

@end
