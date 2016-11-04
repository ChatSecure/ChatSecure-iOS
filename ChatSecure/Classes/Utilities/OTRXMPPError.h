//
//  OTRXMPPError.h
//  Off the Record
//
//  Created by David Chiles on 1/14/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

@class NSXMLElement;

extern NSString *const OTRXMPPErrorDomain;
extern NSString *const OTRXMPPXMLErrorKey;
extern NSString *const OTRXMPPSSLTrustResultKey;
extern NSString *const OTRXMPPSSLCertificateDataKey;
extern NSString *const OTRXMPPSSLHostnameKey;

typedef NS_ENUM(NSUInteger, OTRXMPPErrorCode) {
    OTRXMPPUnsupportedAction,
    OTRXMPPSSLError,
    OTRXMPPDomainError,
    OTRXMPPTorError
};

@interface OTRXMPPError : NSObject

+ (NSString *)errorStringWithSSLStatus:(OSStatus)status;
+ (NSString *)errorStringWithTrustResultType:(SecTrustResultType)resultType;
+ (NSError *)errorForXMLElement:(NSXMLElement *)xmlError;
+ (NSError *)errorForTrustResult:(SecTrustResultType)trustResultType withCertData:(NSData *)certData hostname:(NSString *)hostName;

@end
