//
//  OTRQRCodeReaderDelegate.m
//  ChatSecure
//
//  Created by David Chiles on 7/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRQRCodeReaderDelegate.h"
#import "NSURL+ChatSecure.h"
#import "OTRAccount.h"
#import "OTRProtocolManager.h"

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
    __block XMPPJID *jid = nil;
    __block NSString *fingerprint = nil;
    NSString *otr = [OTRAccount fingerprintStringTypeForFingerprintType:OTRFingerprintTypeOTR];
    [url otr_decodeShareLink:^(XMPPJID * _Nullable inJid, NSArray<NSURLQueryItem*> * _Nullable queryItems) {
        jid = inJid;
        [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:otr]) {
                fingerprint = obj.value;
                *stop = YES;
            }
        }];
    }];
    if (jid) {
        [OTRProtocolManager handleInviteForJID:jid otrFingerprint:fingerprint buddyAddedCallback:nil];
    }
    
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
