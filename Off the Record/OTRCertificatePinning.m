//
//  OTRCertificatePinning.m
//  Off the Record
//
//  Created by David Chiles on 12/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificatePinning.h"
#import "SSKeychain.h"
#import "GCDAsyncSocket.h"
#import "AFSecurityPolicy.h"

#import <CommonCrypto/CommonDigest.h>

#import "OTRConstants.h"

@implementation OTRCertificatePinning

@synthesize delegate;

- (id)initWithDefaultCertificates
{
    if (self = [super init]) {
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        [self loadKeychainCertificates];
    }
    return self;
    
}

- (void)loadKeychainCertificates {
    
    NSSet * allCertificatesSet = [[NSSet setWithArray:self.securityPolicy.pinnedCertificates] setByAddingObjectsFromSet:[OTRCertificatePinning allKeyChainCertificates]];
    
    self.securityPolicy.pinnedCertificates = [allCertificatesSet allObjects];
}

- (BOOL)hasSeenCertificate:(SecTrustRef)trust {
    NSData * unknownCertificateData = [OTRCertificatePinning dataForCertificate:[OTRCertificatePinning certForTrust:trust]];
    if (!unknownCertificateData) {
        return NO;
    }
    [self loadKeychainCertificates];
    
    return [self.securityPolicy evaluateServerTrust:trust];
}

+ (void)addCertificate:(SecCertificateRef)cert {
    
    NSSet * allCerts = [self allKeyChainCertificates];
    NSData * certData = [self dataForCertificate:cert];
    allCerts = [allCerts setByAddingObject:certData];
    
    SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
    keychainQuery.service = kOTRServiceName;
    keychainQuery.account = KOTRCertificatesUsername;
    
    keychainQuery.passwordObject = allCerts;
    
    NSError * error = nil;
    
    [keychainQuery save:&error];
    
    if (error) {
        DDLogError(@"Error saving new certificate to keychain");
    }
    

    
}

+ (NSData *)dataForCertificate:(SecCertificateRef)certificate {
    if (certificate) {
        return (__bridge_transfer NSData *)SecCertificateCopyData(certificate);
    }
    return nil;
}

+ (SecCertificateRef)certForTrust:(SecTrustRef)trust {
    SecCertificateRef certificate = nil;
    CFIndex certificateCount = SecTrustGetCertificateCount(trust);
    if (certificateCount) {
        certificate = SecTrustGetCertificateAtIndex(trust, 0);
    }
    return certificate;
}

+ (SecCertificateRef)certForData:(NSData *)data {
    SecCertificateRef allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    return allowedCertificate;
}

+(NSString*)sha1FingerprintForCertificate:(SecCertificateRef)certificate {
    NSData * certData = [self dataForCertificate:certificate];
    unsigned char sha1Buffer[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, certData.length, sha1Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i)
        [fingerprint appendFormat:@"%02x ",sha1Buffer[i]];
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+(NSSet *)allKeyChainCertificates {
    
    SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
    keychainQuery.service = kOTRServiceName;
    keychainQuery.account = KOTRCertificatesUsername;
    
    NSError * error =nil;
    [keychainQuery fetch:&error];
    
    if (error) {
        DDLogError(@"Error retrieving certificates from keychain");
    }
    
    id passwordObject = keychainQuery.passwordObject;
    if([passwordObject isKindOfClass:[NSSet class]]) {
        return (NSSet *)passwordObject;
    }
    return [NSSet set];
    
}


- (BOOL)socket:(GCDAsyncSocket *)sock shouldFinishConnectionWithTrust:(SecTrustRef)trust status:(OSStatus)status {
    
    BOOL hasSeenCertificate = [self hasSeenCertificate:trust];
    if (!hasSeenCertificate) {
        //Delegate firing off for user to verify with status
        if ([self.delegate respondsToSelector:@selector(newTrust:withStatus:)]) {
            [self.delegate newTrust:trust withStatus:status];
        }
    }
    
    return hasSeenCertificate;
}



@end
