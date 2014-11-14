//
//  QRCodeActivity.m
//  Off the Record
//
//  Created by David on 5/30/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRQRCodeActivity.h"
#import "OTRConstants.h"
#import "UIImage+ChatSecure.h"
#import "UIActivity+ChatSecure.h"
#import "Strings.h"

@implementation OTRQRCodeActivity

-(NSString *)activityTitle
{
    return QR_CODE_STRING;
}
-(NSString *)activityType
{
    return OTRActivityTypeQRCode;
}
-(UIImage *)activityImage
{
    return [UIImage otr_imageWithImage:[UIImage imageNamed:@"chatsecure_qrcode.png"] scaledToSize:[UIActivity otr_defaultImageSize]];
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
