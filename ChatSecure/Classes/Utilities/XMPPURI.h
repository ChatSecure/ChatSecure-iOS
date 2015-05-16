//
//  XMPPURI.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 5/15/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPJID.h"

/** For parsing XMPP URIs (xmpp:username@domain.com) */
@interface XMPPURI : NSObject

@property (nonatomic, strong, readonly) XMPPJID *jid;
/** OTR fingerprint (?otr-fingerprint=xxx) */
@property (nonatomic, strong, readonly) NSString *fingerprint;
/** Multi user chatroom (?join) */
@property (nonatomic, readonly) BOOL isMUC;

/** Returns URI string (xmpp:username@domain.com) */
@property (nonatomic, strong, readonly) NSString *uriString;

- (instancetype) initWithURL:(NSURL*)url;
- (instancetype) initWithURIString:(NSString*)uriString;
/** JID and 40-character hex OTR fingerprint */
- (instancetype) initWithJID:(XMPPJID*)jid fingerprint:(NSString*)fingerprint;

@end
