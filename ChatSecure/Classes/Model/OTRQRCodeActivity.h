//
//  QRCodeActivity.h
//  Off the Record
//
//  Created by David on 5/30/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import UIKit;
#import "OTRQRCodeViewController.h"

extern NSString *const kOTRActivityTypeQRCode;

@interface OTRQRCodeActivity : UIActivity <OTRQRCodeViewControllerDelegate>

@end
