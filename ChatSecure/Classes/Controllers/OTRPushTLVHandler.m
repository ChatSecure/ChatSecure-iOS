//
//  OTRPushTLVHandler.m
//  ChatSecure
//
//  Created by David Chiles on 9/28/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRPushTLVHandler.h"
@import OTRKit;

static const uint16_t OTRPushTLVType = 0x01A4;

@implementation OTRPushTLVHandler

- (instancetype)initWithOTRKit:(OTRKit *)otrKit delegate:(id<OTRPushTLVHandlerDelegate>)delegate;
{
    if (self = [self init]) {
        self.otrKit = otrKit;
        self.delegate = delegate;
        [self.otrKit registerTLVHandler:self];
    }
    return self;
    
}

- (NSArray *)handledTLVTypes
{
    return @[@(OTRPushTLVType)];
}

- (void)receiveTLV:(OTRTLV *)tlv username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol fingerprint:(OTRFingerprint *)fingerprint tag:(id)tag
{
    [self.delegate receivePushData:tlv.data username:username accountName:accountName protocolString:protocol fingerprint:fingerprint];
}

- (void)sendPushData:(NSData *)data username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
    OTRTLV *tlv = [[OTRTLV alloc] initWithType:OTRPushTLVType data:data];
    [self.otrKit encodeMessage:nil tlvs:@[tlv] username:username accountName:accountName protocol:protocol tag:nil];
}

@end
