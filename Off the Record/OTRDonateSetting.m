//
//  OTRDonateSetting.m
//  Off the Record
//
//  Created by Christopher Ballinger on 2/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDonateSetting.h"
#import "Strings.h"

@implementation OTRDonateSetting

-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription
{
    self = [super initWithTitle:newTitle description:newDescription];
    if (self) {
        self.action = @selector(showAlertView);
    }
    return self;
}

-(void)showAlertView
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DONATE_STRING message:DONATE_MESSAGE_STRING delegate:self cancelButtonTitle:CANCEL_STRING otherButtonTitles:DONATE_STRING, nil];
    alert.delegate = self;
    [alert show];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.paypal.com/us/cgi-bin/webscr?cmd=_express-checkout-mobile&useraction=commit&token=EC-1EM38829420923459#m"]];
    }
}


@end
