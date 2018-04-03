//
//  OTRXMPPStream.h
//  ChatSecure
//
//  Created by Chris Ballinger on 2/3/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import XMPPFramework;

@interface OTRXMPPStream : XMPPStream

/**
 * The connected servers hostname. The last attempted hostname before the socket actually connects to an IP address (e.g. after SRV lookup)
 **/
@property (nonatomic, readonly, nullable) NSString *connectedHostName;

@end
