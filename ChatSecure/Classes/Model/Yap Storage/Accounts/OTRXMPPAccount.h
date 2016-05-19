//
//  OTRXMPPAccount.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"

@class XMPPJID, XMPPStream;

@interface OTRXMPPAccount : OTRAccount

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *resource;
@property (nonatomic) int port;

@property (nonatomic, strong) NSString *pushPubsubEndpoint;
@property (nonatomic, strong) NSString *pushPubsubNode;

+ (int)defaultPort;
+ (NSString *)newResource;

+ (instancetype)accountForStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction;

@end
