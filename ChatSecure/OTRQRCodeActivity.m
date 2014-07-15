//
//  QRCodeActivity.m
//  Off the Record
//
//  Created by David on 5/30/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRQRCodeActivity.h"
#import "OTRConstants.h"
#import "OTRUtilities.h"

@implementation OTRQRCodeActivity

-(NSString *)activityTitle
{
    return @"QR Code";
}
-(NSString *)activityType
{
    return OTRActivityTypeQRCode;
}
-(UIImage *)activityImage
{
    CGSize size = CGSizeZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        size = CGSizeMake(43, 43);
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        size = CGSizeMake(55, 55);
    }
    return [OTRUtilities imageWithImage:[UIImage imageNamed:@"chatsecure_qrcode.png"] scaledToSize:size];
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

-(UIViewController *)activityViewController
{
    OTRQRCodeViewController * QRCodeViewController = [[OTRQRCodeViewController alloc] init];
    QRCodeViewController.delegate = self;
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:QRCodeViewController];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    return navController;
}

-(void)didDismiss
{
    [self activityDidFinish:YES];
}

@end
