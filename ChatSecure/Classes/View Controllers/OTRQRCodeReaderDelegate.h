//
//  OTRQRCodeReaderDelegate.h
//  ChatSecure
//
//  Created by David Chiles on 7/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QRCodeReaderViewController.h"

@interface OTRQRCodeReaderDelegate : NSObject <QRCodeReaderDelegate>

@property (nonatomic, strong) NSString *accountUniqueID;
@property (nonatomic, copy) void (^completion)(void);

- (instancetype)initWithAccountUniqueId:(NSString *)accountUniqueID;

@end
