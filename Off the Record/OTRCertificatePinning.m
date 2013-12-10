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
#import "XMPPStream.h"
#import "XMPPJID.h"

#import <CommonCrypto/CommonDigest.h>

#import "OTRConstants.h"

#define keychainKeyPrefix @"sslcert."
#define keychainDictionaryKey @"keychainDictionaryKey"

@implementation OTRCertificatePinning

@synthesize delegate;

- (id)initWithDefaultCertificates
{
    if (self = [super init]) {
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        //[self loadKeychainCertificates];
    }
    return self;
    
}

- (void)loadKeychainCertificatesWithHostName:(NSString *)hostname {
    
    NSSet * allCertificatesSet = [[NSSet setWithArray:self.securityPolicy.pinnedCertificates] setByAddingObjectsFromSet:[self storedCertificatesWithHostName:hostname]];
    
    self.securityPolicy.pinnedCertificates = [allCertificatesSet allObjects];
}

- (BOOL)isValidPinnedTrust:(SecTrustRef)trust withHostName:(NSString *)hostname {
    NSData * unknownCertificateData = [OTRCertificatePinning dataForCertificate:[OTRCertificatePinning certForTrust:trust]];
    if (!unknownCertificateData) {
        return NO;
    }
    [self loadKeychainCertificatesWithHostName:hostname];
    
    return [self.securityPolicy evaluateServerTrust:trust];
}

- (void)addCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname {
    
    NSData * certData = [OTRCertificatePinning dataForCertificate:cert];
    
    if ([hostname length] && [certData length]) {
        SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
        keychainQuery.service = kOTRCertificateServiceName;
        keychainQuery.account = hostname;
        
        NSSet * exisisting = [self storedCertificatesWithHostName:hostname];
        if (![exisisting count]) {
            exisisting = [NSSet set];
        }
        
        keychainQuery.passwordObject = [exisisting setByAddingObject:certData];
        
        NSError * error = nil;
        
        [keychainQuery save:&error];
        
        if (error) {
            DDLogError(@"Error saving new certificate to keychain");
        }

    }
}

-(NSSet *)storedCertificatesWithHostName:(NSString *)hostname {
    NSSet * certificateSet = nil;
    
    SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
    keychainQuery.service = kOTRCertificateServiceName;
    keychainQuery.account = hostname;
    
    NSError * error =nil;
    [keychainQuery fetch:&error];
    
    if (error) {
        DDLogError(@"Error retrieving certificates from keychain");
    }
    
    id passwordObject = keychainQuery.passwordObject;
    if ([passwordObject isKindOfClass:[NSSet class]]) {
        certificateSet = (NSSet *)passwordObject;
    }
    
    return certificateSet;
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
    {
        [fingerprint appendFormat:@"%02x ",sha1Buffer[i]];
    }
    
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (NSDictionary *)allCertificates {
    
}

/**
 * GCDAsyncSocket Delegates
**/
- (BOOL)socket:(GCDAsyncSocket *)sock shouldFinishConnectionWithTrust:(SecTrustRef)trust status:(OSStatus)status {
    
    BOOL hasSeenCertificate = [self isValidPinnedTrust:trust withHostName:xmppStream.connectedHostName];
    if (!hasSeenCertificate) {
        //Delegate firing off for user to verify with status
        if ([self.delegate respondsToSelector:@selector(newTrust:withHostName:withStatus:)]) {
            [self.delegate newTrust:trust withHostName:xmppStream.connectedHostName withStatus:status];
        }
    }
    
    return hasSeenCertificate;
}

- (BOOL)socketShouldManuallyEvaluateTrust:(GCDAsyncSocket *)sock {
    NSArray * certDomains = @[kOTRGoogleTalkDomain,kOTRFacebookDomain];
    NSString * hostname = xmppStream.connectedHostName;
    if ([hostname length]) {
        if([[self storedCertificatesWithHostName:hostname] count] || [certDomains containsObject:hostname])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)socket:(GCDAsyncSocket *)sock shouldTrustPeer:(SecTrustRef)trust
{
    //[self writeCertToDisk:trust withFileName:@"google.cer"];
    [self loadKeychainCertificatesWithHostName:xmppStream.connectedHostName];
    BOOL trusted = [self.securityPolicy evaluateServerTrust:trust];
    return trusted;
}


@end
