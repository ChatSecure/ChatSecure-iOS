//
//  OTRXMPPError.h
//  Off the Record
//
//  Created by David Chiles on 1/14/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import KissXML;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const OTRXMPPErrorDomain;
extern NSString *const OTRXMPPXMLErrorKey;
extern NSString *const OTRXMPPSSLTrustResultKey;
extern NSString *const OTRXMPPSSLCertificateDataKey;
extern NSString *const OTRXMPPSSLHostnameKey;

typedef NS_ENUM(NSInteger, OTRXMPPErrorCode) {
    OTRXMPPErrorCodeUnsupportedAction,
    OTRXMPPErrorCodeSSLError,
    OTRXMPPErrorCodeDomainError,
    OTRXMPPErrorCodeTorError
};

@interface OTRXMPPError : NSObject

+ (nullable NSString *)errorStringWithSSLStatus:(OSStatus)status;
+ (nullable NSString *)errorStringWithTrustResultType:(SecTrustResultType)resultType;
+ (NSError *)errorForXMLElement:(NSXMLElement *)xmlError;
+ (NSError *)errorForTrustResult:(SecTrustResultType)trustResultType withCertData:(NSData *)certData hostname:(NSString *)hostName;

@end
NS_ASSUME_NONNULL_END
