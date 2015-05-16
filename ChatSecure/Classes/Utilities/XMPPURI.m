//
//  XMPPURI.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 5/15/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XMPPURI.h"

static NSString *const kOTRFingerprintQuery = @"otr-fingerprint";

@implementation XMPPURI

- (instancetype) initWithString:(NSString *)uriString {
    if (self = [super init]) {
        [self parseURIString:uriString];
    }
    return self;
}

- (instancetype) initWithURL:(NSURL *)url {
    if (self = [self initWithString:url.absoluteString]) {
    }
    return self;
}

- (instancetype) initWithJID:(XMPPJID *)jid fingerprint:(NSString *)fingerprint {
    if (self = [super init]) {
        _jid = jid;
        _fingerprint = fingerprint;
    }
    return self;
}

- (NSString*) uriString {
    NSString *uriString = nil;
    if (self.fingerprint) {
        uriString = [NSString stringWithFormat:@"xmpp:%@?%@=%@", self.jid.bare, kOTRFingerprintQuery, self.fingerprint];
    } else {
        uriString = [NSString stringWithFormat:@"xmpp:%@", self.jid.bare];
    }
    return uriString;
}

- (void) parseURIString:(NSString*)uriString {
    NSArray *uriComponents = [uriString componentsSeparatedByString:@":"];
    NSString *jidString = nil;
    
    if (uriComponents.count >= 2) {
        NSString *path = uriComponents[1];
        if ([path containsString:@"?"]) {
            NSArray *queryComponents = [path componentsSeparatedByString:@"?"];
            jidString = queryComponents[0];
            NSString *query = queryComponents[1];
            if ([query.lowercaseString isEqualToString:@"join"]) {
                _isMUC = YES;
            } else {
                [self parseFingerprintFromQuery:query];
            }
        } else {
            jidString = path;
        }
    }
    if (jidString) {
        _jid = [XMPPJID jidWithString:jidString];
    }
}

- (void) parseFingerprintFromQuery:(NSString*)query {
    
}

@end
