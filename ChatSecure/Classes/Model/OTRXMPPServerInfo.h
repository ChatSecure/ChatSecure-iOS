//
//  OTRXMPPServerInfo.h
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Mantle;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

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
@interface OTRXMPPServerInfo : MTLModel <MTLJSONSerializing>

#pragma mark Init

/** domain shown at the end of usernames e.g. dukgo.com */
- (instancetype) initWithDomain:(NSString*)domain;

#pragma mark Propertoes

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

/** Set of supported XEPs. See XEPs section below for possible values. */
@property (nonatomic, readonly) NSSet<NSString*> *supportedXEPs;

/** Return image if loaded from local resource bundle */
- (nullable UIImage*) logoImage;

/** Get remote image URL if loaded via internet */
//- (NSURL *) logoURLRelativeToURL:(NSURL*)baseURL;

#pragma mark Utility

/** loaded from bundle */
@property (class, readonly, nullable) NSArray<OTRXMPPServerInfo*> *defaultServerList;

/** Returns all servers (that don't require CAPTCHAs and support the desired XEPs. */
+ (nullable NSArray<OTRXMPPServerInfo*> *)serverListFromJSONData:(NSData*)jsonData;

/** Returns servers with optional filtering. */
+ (nullable NSArray<OTRXMPPServerInfo*> *)serverListFromJSONData:(NSData*)jsonData filterBlock:(BOOL (^)(OTRXMPPServerInfo *server))filterBlock;

#pragma mark Desired XEPs

/** "XEP-0357" - possible value in extensions property. this is required for push messaging */
@property (nonatomic, class, readonly) NSString *XEP_0357;

/** "XEP-0363" - possible value in extensions property. this is required for HTTP upload */
@property (nonatomic, class, readonly) NSString *XEP_0363;

/** Set of XEPs that we need on modern servers, containing the above XEPs. ["XEP-0357, "XEP-0363"] */
@property (nonatomic, class, readonly) NSSet<NSString*> *desiredXEPs;

@end

NS_ASSUME_NONNULL_END
