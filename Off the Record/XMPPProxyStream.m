//
//  XMPPProxyStream.m
//  Off the Record
//
//  Created by Christopher Ballinger on 1/23/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "XMPPProxyStream.h"
#import "GCDAsyncProxySocket.h"

@implementation XMPPProxyStream

- (Class) asyncSocketClass {
    return [GCDAsyncProxySocket class];
}

- (void) setProxyHost:(NSString*)host port:(uint16_t)port version:(GCDAsyncSocketSOCKSVersion)version {
    [(GCDAsyncProxySocket*)self.socket setProxyHost:host port:port version:version];
}

- (void) setProxyUsername:(NSString *)username password:(NSString*)password {
    [(GCDAsyncProxySocket*)self.socket setProxyUsername:username password:password];
}

@end
