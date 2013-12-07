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

+ (SecCertificateRef)certForTrust:(SecTrustRef)trust;
+ (NSData *)dataForCertificate:(SecCertificateRef)certificate;
+ (SecCertificateRef)certForData:(NSData *)data;
- (NSSet *)storedCertificatesWithHostName:(NSString *)hostname;
- (void)addCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname;
+ (NSString*)sha1FingerprintForCertificate:(SecCertificateRef)certificate;

@end
