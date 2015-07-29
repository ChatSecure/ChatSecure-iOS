//
//  OTRXMPPServerInfo.h
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "Mantle.h"
#import <UIKit/UIKit.h>

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

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong, readonly) NSString *serverDescription;
@property (nonatomic, strong, readonly) NSURL *websiteURL;
@property (nonatomic, strong, readonly) NSURL *twitterURL;
@property (nonatomic, strong, readonly) NSURL *privacyPolicyURL;
/** can be relative path or absolute url string */
@property (nonatomic, strong, readonly) NSString *logo;
@property (nonatomic, strong, readonly) NSString *countryCode;
/** root domain e.g. calyxinstitute.org */
@property (nonatomic, strong) NSString *domain;
/** server fqdn e.g. conference.calyxinstitute.org */
@property (nonatomic, strong, readonly) NSString *server;
@property (nonatomic, strong, readonly) NSString *onion;
@property (nonatomic, readonly) uint16_t portNumber;
@property (nonatomic, strong, readonly) NSString *certificate;

/** Return image if loaded from local resource bundle */
- (UIImage*) logoImage;

/** Get remote image URL if loaded via internet */
//- (NSURL *) logoURLRelativeToURL:(NSURL*)baseURL;

/** loaded from bundle */
+ (NSArray *)defaultServerList;
+ (NSArray *)serverListFromJSONData:(NSData*)jsonData;

@end
