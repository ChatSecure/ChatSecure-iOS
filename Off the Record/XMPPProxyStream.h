//
//  XMPPProxyStream.h
//  Off the Record
//
//  Created by Christopher Ballinger on 1/23/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "XMPPStream.h"
#import "GCDAsyncProxySocket.h"

@interface XMPPProxyStream : XMPPStream

- (void) setProxyHost:(NSString*)host port:(uint16_t)port version:(GCDAsyncSocketSOCKSVersion)version;
- (void) setProxyUsername:(NSString *)username password:(NSString*)password;

@end
