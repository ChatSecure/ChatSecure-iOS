//
//  XMPPProxyStream.m
//  ChatSecure
//
//  Created by Chris Ballinger on 2/2/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "ProxyXMPPStream.h"
#import "XMPPInternal.h"

@interface XMPPStream(Overrides)
- (GCDAsyncSocket*) newSocket;
@end

@implementation ProxyXMPPStream

- (void) checkSocketClass {
    if (!self.asyncSocket || ![self.asyncSocket isKindOfClass:[GCDAsyncProxySocket class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Stream socket is of wrong class!" userInfo:nil];
    }
}

- (void) setProxyHost:(NSString*)host port:(uint16_t)port version:(GCDAsyncSocketSOCKSVersion)version {
    [self checkSocketClass];
    dispatch_block_t block = ^{
        [(GCDAsyncProxySocket *)self.asyncSocket setProxyHost:host port:port version:version];
    };
    if (dispatch_get_specific(self.xmppQueueTag))
        block();
    else
        dispatch_sync(self.xmppQueue, block);
}

- (void) setProxyUsername:(NSString *)username password:(NSString*)password {
    [self checkSocketClass];
    dispatch_block_t block = ^{
        [(GCDAsyncProxySocket *)self.asyncSocket setProxyUsername:username password:password];
    };
    if (dispatch_get_specific(self.xmppQueueTag))
        block();
    else
        dispatch_sync(self.xmppQueue, block);
}



/** Override */
- (GCDAsyncSocket*) newSocket {
    GCDAsyncProxySocket *socket = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:self.xmppQueue];
    socket.IPv4PreferredOverIPv6 = !self.preferIPv6;
    return socket;
}

@end
