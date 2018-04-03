//
//  OTRCertificatePinning.h
//  Off the Record
//
//  Created by David Chiles on 12/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import XMPPFramework;

NS_ASSUME_NONNULL_BEGIN
@class AFSecurityPolicy;

@protocol OTRCertificatePinningDelegate <NSObject>

- (void)newTrust:(SecTrustRef)trust withHostName:(NSString *)hostname systemTrustResult:(SecTrustResultType)trustResultType;

@end

@interface OTRCertificatePinning : XMPPModule

@property (nonatomic, strong, readonly) AFSecurityPolicy *securityPolicy;
@property (nonatomic, weak, nullable) id<OTRCertificatePinningDelegate> delegate;

+ (void)addCertificateData:(NSData*)certificateData withHostName:(NSString *)hostname;
+ (void)addCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname;

+ (nullable NSString*)sha256FingerprintForCertificate:(SecCertificateRef)certificate;
+ (NSString*)sha256FingerprintForCertificateData:(NSData*)certificateData;
+ (NSDictionary<NSString*,NSArray<NSData*>*> *)allCertificates;
+ (nullable NSArray<NSData*> *)storedCertificatesWithHostName:(NSString *)hostname;
+ (nullable SecCertificateRef)certForTrust:(SecTrustRef)trust;
+ (nullable NSData *)dataForCertificate:(SecCertificateRef)certificate;

+ (nullable SecCertificateRef)certForData:(NSData *)data;

+ (void)deleteAllCertificatesWithHostName:(NSString *)hostname;
+ (void)deleteCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname;

+ (nullable id)publicKeyWithCertData:(NSData *)certData;

@end
NS_ASSUME_NONNULL_END
