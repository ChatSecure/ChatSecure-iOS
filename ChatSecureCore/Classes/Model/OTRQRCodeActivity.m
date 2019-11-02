//
//  QRCodeActivity.m
//  Off the Record
//
//  Created by David on 5/30/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRQRCodeActivity.h"
#import "UIImage+ChatSecure.h"
#import "UIActivity+ChatSecure.h"

@import OTRAssets;

NSString *const kOTRActivityTypeQRCode = @"OTRActivityTypeQRCode";

@interface OTRQRCodeActivity()
@property (nonatomic, copy, readonly) NSString *qrString;

@end

@implementation OTRQRCodeActivity

-(NSString *)activityTitle
{
    return QR_CODE_STRING();
}

-(NSString *)activityType
{
    return kOTRActivityTypeQRCode;
}

-(UIImage *)activityImage
{
    return [UIImage otr_imageWithImage:[UIImage imageNamed:@"chatsecure_qrcode.png" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] scaledToSize:[UIActivity otr_defaultImageSize]];
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    BOOL canPerformActivity = NO;
    if (activityItems.count == 1) {
        id activityItem = activityItems[0];
        if ([activityItem isKindOfClass:[NSString class]] || [activityItem isKindOfClass:[NSURL class]]) {
            canPerformActivity = YES;
        }
    }
    return canPerformActivity;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    id activityItem = activityItems[0];
    if ([activityItem isKindOfClass:[NSString class]]) {
        _qrString = activityItem;
    } else if ([activityItem isKindOfClass:[NSURL class]]) {
        NSURL *url = activityItem;
        _qrString = url.absoluteString;
    }
}

-(UIViewController *)activityViewController
{
    OTRQRCodeViewController * QRCodeViewController = [[OTRQRCodeViewController alloc] initWithQRString:self.qrString];
    QRCodeViewController.delegate = self;
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:QRCodeViewController];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    return navController;
}

#pragma mark OTRQRCodeViewControllerDelegate

-(void)didDismissQRCodeViewController:(OTRQRCodeViewController*)qrCodeViewController
{
    [self activityDidFinish:YES];
}

@end
