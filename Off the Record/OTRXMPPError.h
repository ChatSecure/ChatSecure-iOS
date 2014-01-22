//
//  OTRXMPPError.h
//  Off the Record
//
//  Created by David Chiles on 1/14/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSXMLElement;

extern NSString *const OTRXMPPErrorDomain;
extern NSString *const OTRXMPPXMLErrorKey;
extern NSString *const OTRXMPPSSLStatusKey;
extern NSString *const OTRXMPPSSLCertificateDataKey;
extern NSString *const OTRXMPPSSLHostnameKey;

typedef NS_ENUM(NSUInteger, OTRXMPPErrorCode) {
    OTRXMPPUnsupportedAction,
    OTRXMPPXMLError,
    OTRXMPPSSLError,
    OTRXMPPDomainError,
    OTRXMPPTorError
};

@interface OTRXMPPError : NSObject

+ (NSString *)errorStringWithSSLStatus:(OSStatus)status;

+ (NSError *)errorForXMLElement:(NSXMLElement *)xmlError;
+ (NSError *)errorForSSLSatus:(OSStatus)status withCertData:(NSData *)certData hostname:(NSString *)hostName;

@end
