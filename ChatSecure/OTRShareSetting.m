//
//  OTRShareSetting.m
//  Off the Record
//
//  Created by David on 11/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRShareSetting.h"
#import "Strings.h"
#import "OTRAppDelegate.h"
#import "OTRQRCodeViewController.h"
#import "OTRUtilities.h"
#import "OTRActivityItemProvider.h"
#import "OTRQRCodeActivity.h"
#import "OTRConstants.h"

@implementation OTRShareSetting

-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription
{
    self = [super initWithTitle:newTitle description:newDescription];
    if (self) {
        __weak typeof(self)weakSelf = self;
        self.actionBlock = ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf showActionSheet];
        };
    }
    return self;
}

-(void)showActionSheet
{
    OTRActivityItemProvider * itemProvider = [[OTRActivityItemProvider alloc] init];
    OTRQRCodeActivity * qrCodeActivity = [[OTRQRCodeActivity alloc] init];
    
    UIActivityViewController * activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[itemProvider] applicationActivities:@[qrCodeActivity]];
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
    
    [self.delegate presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark MFMessageComposeViewControllerDelegate methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self.delegate dismissModalViewControllerAnimated:YES];
}

#pragma mark MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)erro
{
    [self.delegate dismissModalViewControllerAnimated:YES];
}

@end
