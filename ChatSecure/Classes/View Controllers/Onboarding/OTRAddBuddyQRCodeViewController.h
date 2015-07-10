//
//  OTRAddBuddyQRCodeViewController.h
//  ChatSecure
//
//  Created by David Chiles on 7/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "QRCodeReaderViewController.h"

@interface OTRAddBuddyQRCodeViewController : QRCodeReaderViewController


- (instancetype)initWIthAccountID:(NSString *)accountUniqueID completion:(void (^)(void))completion;;

@end
