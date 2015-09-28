//
//  OTRPushTLVHandler.m
//  ChatSecure
//
//  Created by David Chiles on 9/28/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRPushTLVHandler.h"
#import "OTRKit.h"

@implementation OTRPushTLVHandler

- (instancetype)initWithDelegate:(id<OTRPushTLVHandlerDelegate>)delegate
{
    if (self = [self init]) {
        _delegate = delegate;
    }
    return self;
    
}

- (NSArray *)handledTLVTypes
{
    return @[@(0x01A4)];
}

- (void)receiveTLV:(OTRTLV *)tlv username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag
{
    [self.delegate receivePushData:tlv.data username:username accountName:accountName protocolString:protocol];
}

@end
