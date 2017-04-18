//
//  OTRXMPPServerInfo.h
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Mantle;
@import UIKit;

/*
 {
 "name": "Calyx Institute",
 "description": "Non-profit education and research organization focused on privacy technology.",
 "website": "https://www.calyxinstitute.org",
 "twitter": "https://twitter.com/calyxinstitute",
 "privacy_policy": "https://www.calyxinstitute.org/legal/privacy-policy",
 "logo": "images/calyx.jpg",
 "country_code": "US",
 "domain": "calyxinstitute.org",
 "server": "conference.calyxinstitute.org",
 "onion": "ijeeynrc6x2uy5ob.onion",
 "port": 5222,
 "certificate": "..."
 }
 */
NS_ASSUME_NONNULL_BEGIN
@interface OTRXMPPServerInfo : MTLModel <MTLJSONSerializing>

/** domain shown at the end of usernames e.g. dukgo.com */
- (instancetype) initWithDomain:(NSString*)domain;

/** domain shown at the end of usernames e.g. dukgo.com */
@property (nonatomic, strong, readonly) NSString *domain;

@property (nonatomic, strong, readonly, nullable) NSString *name;
@property (nonatomic, strong, readonly, nullable) NSString *serverDescription;
@property (nonatomic, strong, readonly, nullable) NSURL *websiteURL;
@property (nonatomic, strong, readonly, nullable) NSURL *twitterURL;
@property (nonatomic, strong, readonly, nullable) NSURL *privacyPolicyURL;
/** can be relative path or absolute url string */
@property (nonatomic, strong, readonly, nullable) NSString *logo;
@property (nonatomic, strong, readonly, nullable) NSString *countryCode;
/** server fqdn e.g. xmpp.dukgo.com */
@property (nonatomic, strong, readonly, nullable) NSString *server;
@property (nonatomic, strong, readonly, nullable) NSString *onion;
/** Defaults to 5222 */
@property (nonatomic, readonly) in_port_t portNumber;
@property (nonatomic, strong, readonly, nullable) NSString *certificate;
/** If the server has a CAPTCHA challenge when registering. We currently don't support CAPTCHAs, so those results will be filtered out of . */
@property (nonatomic, readonly) BOOL requiresCaptcha;

/** Return image if loaded from local resource bundle */
- (nullable UIImage*) logoImage;

/** Get remote image URL if loaded via internet */
//- (NSURL *) logoURLRelativeToURL:(NSURL*)baseURL;

/** loaded from bundle */
@property (class, readonly, nullable) NSArray<OTRXMPPServerInfo*> *defaultServerList;

/** Returns all servers (that don't require CAPTCHAs) */
+ (nullable NSArray<OTRXMPPServerInfo*> *)serverListFromJSONData:(NSData*)jsonData;

/** Returns servers with optional CAPTCHA filtering. filterRequiresCaptcha=YES will remove results. */
+ (nullable NSArray<OTRXMPPServerInfo*> *)serverListFromJSONData:(NSData*)jsonData filterRequiresCaptcha:(BOOL)filterRequiresCaptcha;

@end
NS_ASSUME_NONNULL_END
