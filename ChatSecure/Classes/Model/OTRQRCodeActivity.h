//
//  QRCodeActivity.h
//  Off the Record
//
//  Created by David on 5/30/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRQRCodeViewController.h"

extern NSString *const kOTRActivityTypeQRCode;

@interface OTRQRCodeActivity : UIActivity <OTRQRCodeViewControllerDelegate>

@end
