//
//  OTRQRCodeReaderDelegate.m
//  ChatSecure
//
//  Created by David Chiles on 7/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRQRCodeReaderDelegate.h"
#import "NSURL+ChatSecure.h"


@implementation OTRQRCodeReaderDelegate

- (instancetype)initWithAccount:(OTRAccount *)account
{
    if (self = [super init]) {
        self.account = account;
    }
    return self;
}


#pragma - mark QRCodeReaderViewControllerDelegate

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    NSURL *url = [NSURL URLWithString:result];
    
    //Todo: Check to make sure url is really a share url
    __block NSString *username = nil;
    __block NSString *fingerprint = nil;
    [url otr_decodeShareLink:^(NSString *uName, NSString *fPrint) {
        username = uName;
        fingerprint = fPrint;
    }];
    
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
