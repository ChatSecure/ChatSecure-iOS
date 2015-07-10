//
//  OTRQRCodeReaderDelegate.m
//  ChatSecure
//
//  Created by David Chiles on 7/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRQRCodeReaderDelegate.h"


@implementation OTRQRCodeReaderDelegate

- (instancetype)initWithAccountUniqueId:(NSString *)accountUniqueID
{
    if (self = [super init]) {
        self.accountUniqueID = accountUniqueID;
    }
    return self;
}


#pragma - mark QRCodeReaderViewControllerDelegate

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    //send subscription request to JID
    [self done];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self done];
}

- (void)done
{
    if (self.completion) {
        self.completion();
    }
}

@end
