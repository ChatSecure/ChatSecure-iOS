//
//  OTRCertificatePinning.h
//  Off the Record
//
//  Created by David Chiles on 12/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "XMPPCertificatePinning.h"


@protocol OTRCertificatePinningDelegate <NSObject>

- (void)newTrust:(SecTrustRef)trust withHostName:(NSString *)hostname withStatus:(OSStatus)status;

@end

@interface OTRCertificatePinning : XMPPCertificatePinning

@property (nonatomic, weak) id<OTRCertificatePinningDelegate> delegate;
@property (nonatomic) BOOL doNotManuallyEvaluateOverride;

- (NSArray *)storedCertificatesWithHostName:(NSString *)hostname;
- (void)addCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname;

+ (NSString*)sha1FingerprintForCertificate:(SecCertificateRef)certificate;
+ (NSDictionary *)allCertificates;
+ (NSArray *)storedCertificatesWithHostName:(NSString *)hostname;
+ (SecCertificateRef)certForTrust:(SecTrustRef)trust;
+ (NSData *)dataForCertificate:(SecCertificateRef)certificate;
+ (SecCertificateRef)certForData:(NSData *)data;
+ (void)deleteAllCertificatesWithHostName:(NSString *)hostname;
+ (void)deleteCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname;
+ (NSDictionary *)bundledCertificates;

@end
