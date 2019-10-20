//
//  OTRXMPPError.m
//  Off the Record
//
//  Created by David Chiles on 1/14/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPError.h"

@import XMPPFramework;
@import OTRAssets;

#import "ChatSecureCoreCompat-Swift.h"

NSString *const OTRXMPPErrorDomain                = @"OTRXMPPErrorDomain";
NSString *const OTRXMPPXMLErrorKey                = @"OTRXMPPXMLErrorKey";
NSString *const OTRXMPPSSLTrustResultKey          = @"OTRXMPPSSLTrustResultKey";
NSString *const OTRXMPPSSLCertificateDataKey      = @"OTRXMPPSSLCertificateDataKey";
NSString *const OTRXMPPSSLHostnameKey             = @"OTRXMPPSSLHostnameKey";

@implementation OTRXMPPError

+ (NSError *)errorForTrustResult:(SecTrustResultType)trustResultType withCertData:(NSData *)certData hostname:(NSString *)hostName
{
    NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
    userInfo[OTRXMPPSSLTrustResultKey] = @(trustResultType);
    if (certData) {
        userInfo[OTRXMPPSSLCertificateDataKey] = certData;
    }
    if (hostName.length) {
        userInfo[OTRXMPPSSLHostnameKey] = hostName;
    }
    
    NSError * error = [NSError errorWithDomain:OTRXMPPErrorDomain code:OTRXMPPErrorCodeSSLError userInfo:userInfo];
    return error;
}

+ (NSError *)errorForXMLElement:(NSXMLElement *)xmlError
{
    NSString * errorString = [self errorStringForXMLElement:xmlError];
    
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    if (errorString) {
        [userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
    }
    
    if(xmlError) {
        [userInfo setObject:xmlError forKey:OTRXMPPXMLErrorKey];
    }
    
    NSError * error = [NSError XMPPXMLError:[self errorEnumForXMLElement:xmlError] userInfo:userInfo];
    
    return error;
}

+ (OTRXMPPXMLError)errorEnumForXMLElement:(NSXMLElement *)xmlError {
    
    if([[[xmlError elementsForName:@"error"] firstObject] elementForName:@"conflict" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"]) {
        return OTRXMPPXMLErrorConflict;
    } else if([[[xmlError elementsForName:@"error"] firstObject] elementForName:@"not-acceptable" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"]) {
        return OTRXMPPXMLErrorNotAcceptable;
    } else if ([[[xmlError elementsForName:@"error"] firstObject] elementForName:@"policy-violation" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"]) {
        return OTRXMPPXMLErrorPolicyViolation;
    } else if ([[[xmlError elementsForName:@"error"] firstObject] elementForName:@"service-unavailable" xmlns:@"urn:ietf:params:xml:ns:xmpp-stanzas"]) {
        return OTRXMPPXMLErrorServiceUnavailable;
    } else {
        return OTRXMPPXMLErrorUnknownError;
    }
}

+ (NSString *)errorStringForXMLElement:(NSXMLElement *)xmlError
{
    NSString * errorString = nil;
    NSArray * elements = [xmlError elementsForName:@"error"];
    if ([elements count]) {
        elements = [[elements firstObject] elementsForName:@"text"];
        if ([elements count]) {
            errorString = [[elements firstObject] stringValue];
        }
    }
    return errorString;
}

+ (NSString *)errorStringWithTrustResultType:(SecTrustResultType)resultType
{
    switch (resultType) {
        case kSecTrustResultInvalid: return @"Error evaluating certificate";
        case kSecTrustResultDeny: return @"User specified to deny trust";
        case kSecTrustResultUnspecified: return @"Rejected Certificate";
        case kSecTrustResultRecoverableTrustFailure : return @"Rejected Certificate";
        case kSecTrustResultFatalTrustFailure :return @"Bad Certificate";
        case kSecTrustResultOtherError: return @"Error evaluating certificate";
        case kSecTrustResultProceed: return @"Proceed";
        default: return @"Unknown";
    }
    return nil;
}

+ (NSString *)errorStringWithSSLStatus:(OSStatus)status {
    
    switch (status) {
        case noErr : return noErrString();
        case errSSLProtocol : return errSSLProtocolString();
        case errSSLNegotiation : return errSSLNegotiationString();
        case errSSLFatalAlert : return errSSLFatalAlertString();
        case errSSLWouldBlock : return errSSLWouldBlockString();
        case errSSLSessionNotFound : return errSSLSessionNotFoundString();
        case errSSLClosedGraceful : return errSSLClosedGracefulString();
        case errSSLClosedAbort : return errSSLClosedAbortString();
        case errSSLXCertChainInvalid : return errSSLXCertChainInvalidString();
        case errSSLBadCert : return errSSLBadCertString();
        case errSSLCrypto : return errSSLCryptoString();
        case errSSLInternal : return errSSLInternalString();
        case errSSLModuleAttach : return errSSLModuleAttachString();
        case errSSLUnknownRootCert : return errSSLUnknownRootCertString();
        case errSSLNoRootCert : return errSSLNoRootCertString();
        case errSSLCertExpired : return errSSLCertExpiredString();
        case errSSLCertNotYetValid : return errSSLCertNotYetValidString();
        case errSSLClosedNoNotify : return errSSLClosedNoNotifyString();
        case errSSLBufferOverflow : return errSSLBufferOverflowString();
        case errSSLBadCipherSuite : return errSSLBadCipherSuiteString();
        case errSSLPeerUnexpectedMsg : return errSSLPeerUnexpectedMsgString();
        case errSSLPeerBadRecordMac : return errSSLPeerBadRecordMacString();
        case errSSLPeerDecryptionFail : return errSSLPeerDecryptionFailString();
        case errSSLPeerRecordOverflow : return errSSLPeerRecordOverflowString();
        case errSSLPeerDecompressFail : return errSSLPeerDecompressFailString();
        case errSSLPeerHandshakeFail : return errSSLPeerHandshakeFailString();
        case errSSLPeerBadCert : return errSSLPeerBadCertString();
        case errSSLPeerUnsupportedCert : return errSSLPeerUnsupportedCertString();
        case errSSLPeerCertRevoked 	: return errSSLPeerCertRevokedString();
        case errSSLPeerCertExpired : return errSSLPeerCertExpiredString();
        case errSSLPeerCertUnknown : return errSSLPeerCertUnknownString();
        case errSSLIllegalParam : return errSSLIllegalParamString();
        case errSSLPeerUnknownCA : return errSSLPeerUnknownCAString();
        case errSSLPeerAccessDenied : return errSSLPeerAccessDeniedString();
        case errSSLPeerDecodeError : return errSSLPeerDecodeErrorString();
        case errSSLPeerDecryptError : return errSSLPeerDecryptErrorString();
        case errSSLPeerExportRestriction : return errSSLPeerExportRestrictionString();
        case errSSLPeerProtocolVersion : return errSSLPeerProtocolVersionString();
        case errSSLPeerInsufficientSecurity : return errSSLPeerInsufficientSecurityString();
        case errSSLPeerInternalError : return errSSLPeerInternalErrorString();
        case errSSLPeerUserCancelled : return errSSLPeerUserCancelledString();
        case errSSLPeerNoRenegotiation : return errSSLPeerNoRenegotiationString();
        case errSSLPeerAuthCompleted : return errSSLPeerAuthCompletedString();
        case errSSLClientCertRequested : return errSSLClientCertRequestedString();
        case errSSLHostNameMismatch : return errSSLHostNameMismatchString();
        case errSSLConnectionRefused : return errSSLConnectionRefusedString();
        case errSSLDecryptionFail : return errSSLDecryptionFailString();
        case errSSLBadRecordMac : return errSSLBadRecordMacString();
        case errSSLRecordOverflow : return errSSLRecordOverflowString();
        case errSSLBadConfiguration : return errSSLBadConfigurationString();
        case errSSLUnexpectedRecord : return errSSLUnexpectedRecordString();
    }
    return nil;
}

@end
