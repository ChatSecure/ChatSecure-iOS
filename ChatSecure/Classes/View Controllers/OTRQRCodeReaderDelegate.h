//
//  OTRQRCodeReaderDelegate.h
//  ChatSecure
//
//  Created by David Chiles on 7/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import QRCodeReaderViewController;
@class OTRAccount;

@interface OTRQRCodeReaderDelegate : NSObject <QRCodeReaderDelegate>

@property (nonatomic, strong) OTRAccount *account;
@property (nonatomic, copy) void (^completion)(void);

- (instancetype)initWithAccount:(OTRAccount *)account;

@end
