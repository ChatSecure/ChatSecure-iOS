//
//  OTRXMPPLoginHandler.h
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRBaseLoginViewController.h"
#import "OTRXMPPAccount.h"
#import "OTRLoginHandler.h"

@class XLFormViewController, OTRXMPPManager;

@interface OTRXMPPLoginHandler : NSObject <OTRBaseLoginViewControllerHandlerProtocol>

@property (nonatomic, copy) void (^completion)(OTRAccount * account, NSError *error);
@property (nonatomic, strong, readonly) OTRXMPPManager *xmppManager;

- (OTRAccount *)moveValues:(XLFormDescriptor *)form intoAccount:(OTRXMPPAccount *)account;

- (void)prepareForXMPPConnectionFrom:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account;

- (void)receivedNotification:(NSNotification *)notification;

@end
