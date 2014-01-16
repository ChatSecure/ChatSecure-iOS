//
//  OTRErrorManager.m
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRErrorManager.h"
#import "Strings.h"

@implementation OTRErrorManager

+ (NSString *)errorStringWithSSLStatus:(OSStatus)status {
    
    switch (status) {
        case noErr : return noErrString;
        case errSSLProtocol : return errSSLProtocolString;
        case errSSLNegotiation : return errSSLNegotiationString;
        case errSSLFatalAlert : return errSSLFatalAlertString;
        case errSSLWouldBlock : return errSSLWouldBlockString;
        case errSSLSessionNotFound : return errSSLSessionNotFoundString;
        case errSSLClosedGraceful : return errSSLClosedGracefulString;
        case errSSLClosedAbort : return errSSLClosedAbortString;
        case errSSLXCertChainInvalid : return errSSLXCertChainInvalidString;
        case errSSLBadCert : return errSSLBadCertString;
        case errSSLCrypto : return errSSLCryptoString;
        case errSSLInternal : return errSSLInternalString;
        case errSSLModuleAttach : return errSSLModuleAttachString;
        case errSSLUnknownRootCert : return errSSLUnknownRootCertString;
        case errSSLNoRootCert : return errSSLNoRootCertString;
        case errSSLCertExpired : return errSSLCertExpiredString;
        case errSSLCertNotYetValid : return errSSLCertNotYetValidString;
        case errSSLClosedNoNotify : return errSSLClosedNoNotifyString;
        case errSSLBufferOverflow : return errSSLBufferOverflowString;
        case errSSLBadCipherSuite : return errSSLBadCipherSuiteString;
        case errSSLPeerUnexpectedMsg : return errSSLPeerUnexpectedMsgString;
        case errSSLPeerBadRecordMac : return errSSLPeerBadRecordMacString;
        case errSSLPeerDecryptionFail : return errSSLPeerDecryptionFailString;
        case errSSLPeerRecordOverflow : return errSSLPeerRecordOverflowString;
        case errSSLPeerDecompressFail : return errSSLPeerDecompressFailString;
        case errSSLPeerHandshakeFail : return errSSLPeerHandshakeFailString;
        case errSSLPeerBadCert : return errSSLPeerBadCertString;
        case errSSLPeerUnsupportedCert : return errSSLPeerUnsupportedCertString;
        case errSSLPeerCertRevoked 	: return errSSLPeerCertRevokedString;
        case errSSLPeerCertExpired : return errSSLPeerCertExpiredString;
        case errSSLPeerCertUnknown : return errSSLPeerCertUnknownString;
        case errSSLIllegalParam : return errSSLIllegalParamString;
        case errSSLPeerUnknownCA : return errSSLPeerUnknownCAString;
        case errSSLPeerAccessDenied : return errSSLPeerAccessDeniedString;
        case errSSLPeerDecodeError : return errSSLPeerDecodeErrorString;
        case errSSLPeerDecryptError : return errSSLPeerDecryptErrorString;
        case errSSLPeerExportRestriction : return errSSLPeerExportRestrictionString;
        case errSSLPeerProtocolVersion : return errSSLPeerProtocolVersionString;
        case errSSLPeerInsufficientSecurity : return errSSLPeerInsufficientSecurityString;
        case errSSLPeerInternalError : return errSSLPeerInternalErrorString;
        case errSSLPeerUserCancelled : return errSSLPeerUserCancelledString;
        case errSSLPeerNoRenegotiation : return errSSLPeerNoRenegotiationString;
        case errSSLPeerAuthCompleted : return errSSLPeerAuthCompletedString;
        case errSSLClientCertRequested : return errSSLClientCertRequestedString;
        case errSSLHostNameMismatch : return errSSLHostNameMismatchString;
        case errSSLConnectionRefused : return errSSLConnectionRefusedString;
        case errSSLDecryptionFail : return errSSLDecryptionFailString;
        case errSSLBadRecordMac : return errSSLBadRecordMacString;
        case errSSLRecordOverflow : return errSSLRecordOverflowString;
        case errSSLBadConfiguration : return errSSLBadConfigurationString;
        case errSSLUnexpectedRecord : return errSSLUnexpectedRecordString;
    }
}


@end
