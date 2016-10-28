//
//  OTRCertificatePinning.h
//  Off the Record
//
//  Created by David Chiles on 12/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import XMPPFramework;

@class AFSecurityPolicy;

@protocol OTRCertificatePinningDelegate <NSObject>

- (void)newTrust:(SecTrustRef)trust withHostName:(NSString *)hostname systemTrustResult:(SecTrustResultType)trustResultType;

@end

@interface OTRCertificatePinning : XMPPModule

@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property (nonatomic, weak) id<OTRCertificatePinningDelegate> delegate;

+ (instancetype)defaultCertificates;

+ (void)addCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname;

+ (NSString*)sha256FingerprintForCertificate:(SecCertificateRef)certificate;
+ (NSDictionary *)allCertificates;
+ (NSArray *)storedCertificatesWithHostName:(NSString *)hostname;
+ (SecCertificateRef)certForTrust:(SecTrustRef)trust;
+ (NSData *)dataForCertificate:(SecCertificateRef)certificate;
+ (SecCertificateRef)certForData:(NSData *)data;

+ (void)deleteAllCertificatesWithHostName:(NSString *)hostname;
+ (void)deleteCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname;

+ (id)publicKeyWithCertData:(NSData *)certData;

@end
