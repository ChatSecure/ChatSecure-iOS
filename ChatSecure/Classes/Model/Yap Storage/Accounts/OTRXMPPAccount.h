//
//  OTRXMPPAccount.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"
#import "OTRvCard.h"

@class XMPPJID, XMPPStream, XMPPvCardTemp;

NS_ASSUME_NONNULL_BEGIN
@interface OTRXMPPAccount : OTRAccount <OTRvCard>

@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *resource;
@property (nonatomic) uint16_t port;

@property (nonatomic, strong, nullable) NSString *pushPubsubEndpoint;
@property (nonatomic, strong, nullable) NSString *pushPubsubNode;

+ (uint16_t)defaultPort;
+ (NSString *)newResource;

+ (nullable instancetype)accountForStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction;

@end
NS_ASSUME_NONNULL_END
