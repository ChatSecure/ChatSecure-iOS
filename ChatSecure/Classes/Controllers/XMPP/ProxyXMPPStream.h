//
//  ProxyXMPPStream.h
//  ChatSecure
//
//  Created by Chris Ballinger on 2/2/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@import XMPPFramework;
@import ProxyKit;

@interface ProxyXMPPStream : XMPPStream

/**
 * Sets SOCKS proxy host and port
 **/
- (void) setProxyHost:(NSString*)host port:(uint16_t)port version:(GCDAsyncSocketSOCKSVersion)version;
- (void) setProxyUsername:(NSString *)username password:(NSString*)password;

@end
