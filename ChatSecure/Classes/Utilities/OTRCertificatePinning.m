//
//  OTRCertificatePinning.m
//  Off the Record
//
//  Created by David Chiles on 12/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificatePinning.h"
@import SAMKeychain;
@import CocoaAsyncSocket;
@import AFNetworking;
@import XMPPFramework;


#import <CommonCrypto/CommonDigest.h>

#import "OTRConstants.h"
#import "OTRLog.h"


///////////////////////////////////////////////
//Coppied from AFSecurityPolicy.m
///////////////////////////////////////////////
static id AFPublicKeyForCertificate(NSData *certificate) {
    SecCertificateRef allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificate);
    NSCParameterAssert(allowedCertificate);
    
    SecCertificateRef allowedCertificates[] = {allowedCertificate};
    CFArrayRef tempCertificates = CFArrayCreate(NULL, (const void **)allowedCertificates, 1, NULL);
    
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef allowedTrust = NULL;
#if defined(NS_BLOCK_ASSERTIONS)
    SecTrustCreateWithCertificates(tempCertificates, policy, &allowedTrust);
#else
    OSStatus status = SecTrustCreateWithCertificates(tempCertificates, policy, &allowedTrust);
    NSCAssert(status == errSecSuccess, @"SecTrustCreateWithCertificates error: %ld", (long int)status);
#endif
    
    SecTrustResultType result = 0;
    
#if defined(NS_BLOCK_ASSERTIONS)
    SecTrustEvaluate(allowedTrust, &result);
#else
    status = SecTrustEvaluate(allowedTrust, &result);
    NSCAssert(status == errSecSuccess, @"SecTrustEvaluate error: %ld", (long int)status);
#endif
    
    SecKeyRef allowedPublicKey = SecTrustCopyPublicKey(allowedTrust);
    //NSCParameterAssert(allowedPublicKey);
    
    CFRelease(allowedTrust);
    CFRelease(policy);
    CFRelease(tempCertificates);
    CFRelease(allowedCertificate);
    
    return (__bridge_transfer id)allowedPublicKey;
}



@interface OTRCertificatePinning () <XMPPStreamDelegate>

@end

@implementation OTRCertificatePinning

- (instancetype)init
{
    if (self = [super init]) {
        _securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
        self.securityPolicy.validatesDomainName = NO;
        self.securityPolicy.allowInvalidCertificates = YES;
    }
    return self;
    
}

- (void)loadKeychainCertificatesWithHostName:(NSString *)hostname {
    
    NSArray * hostnameCertificatesArray = [OTRCertificatePinning storedCertificatesWithHostName:hostname];
    
    
    self.securityPolicy.pinnedCertificates = [[NSSet alloc] initWithArray:hostnameCertificatesArray];
}

- (BOOL)isValidPinnedTrust:(SecTrustRef)trust withHostName:(NSString *)hostname {
    NSData * unknownCertificateData = [OTRCertificatePinning dataForCertificate:[OTRCertificatePinning certForTrust:trust]];
    if (!unknownCertificateData) {
        return NO;
    }
    [self loadKeychainCertificatesWithHostName:hostname];
    
    return [self.securityPolicy evaluateServerTrust:trust forDomain:hostname];
}

/**
 *For simulator use and collecting certs in documents folder then moved to App Bundle
 **/
-(void)writeCertToDisk:(SecTrustRef)trust withFileName:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if (basePath) {
        NSString * path = [NSString pathWithComponents:@[basePath,fileName]];
        CFIndex certificateCount = SecTrustGetCertificateCount(trust);
        if (certificateCount) {
            SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, 0);
            NSData * data = (__bridge_transfer NSData *)SecCertificateCopyData(certificate);
            [data writeToFile:path atomically:YES];
        }
    }
}

+ (void)addCertificateData:(NSData*)certificateData withHostName:(NSString *)hostname {
    NSData *certData = certificateData;
    if ([hostname length] && [certData length]) {
        SAMKeychainQuery * keychainQuery = [[SAMKeychainQuery alloc] init];
        keychainQuery.service = kOTRCertificateServiceName;
        keychainQuery.account = hostname;
        
        NSArray * exisisting = [self storedCertificatesWithHostName:hostname];
        if (![exisisting count]) {
            exisisting = [NSArray array];
        }
        __block BOOL alreadySaved = NO;
        [exisisting enumerateObjectsUsingBlock:^(NSData * obj, NSUInteger idx, BOOL *stop) {
            if ([obj isEqualToData:certData]) {
                alreadySaved = YES;
                *stop = YES;
            }
        }];
        
        if (!alreadySaved) {
            keychainQuery.passwordObject = [exisisting arrayByAddingObject:certData];
            NSError * error = nil;
            
            [keychainQuery save:&error];
            
            if (error) {
                DDLogError(@"Error saving new certificate to keychain: %@", error);
            }
        }
    }
}

+ (void)addCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname {
    NSData * certData = [OTRCertificatePinning dataForCertificate:cert];
    [self addCertificateData:certData withHostName:hostname];
}

+ (NSArray *)storedCertificatesWithHostName:(NSString *)hostname {
    NSArray * certificateArray = nil;
    
    SAMKeychainQuery * keychainQuery = [self keychainQueryForHostName:hostname];
    
    NSError * error =nil;
    [keychainQuery fetch:&error];
    
    if (error) {
        DDLogError(@"Error retrieving certificates from keychain: %@", error);
    }
    
    id passwordObject = keychainQuery.passwordObject;
    if ([passwordObject isKindOfClass:[NSArray class]]) {
        certificateArray = (NSArray *)passwordObject;
    }
    
    return certificateArray;
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
    SecCertificateRef allowedCertificate = NULL;
    if([ data length]) {
        allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
    }
    return allowedCertificate;
}

+(NSString*)sha256FingerprintForCertificateData:(NSData*)certificateData {
    NSData *certData = certificateData;
    NSUInteger bufferLength = CC_SHA256_DIGEST_LENGTH;
    unsigned char sha256Buffer[bufferLength];
    CC_SHA256(certData.bytes, (CC_LONG)certData.length, sha256Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:bufferLength * 3];
    for (int i = 0; i < bufferLength; ++i)
    {
        [fingerprint appendFormat:@"%02x",sha256Buffer[i]];
    }
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+(NSString*)sha256FingerprintForCertificate:(SecCertificateRef)certificate {
    NSData * certData = [self dataForCertificate:certificate];
    return [self sha256FingerprintForCertificateData:certData];
}

+ (NSDictionary *)allCertificates {
    NSMutableDictionary * resultsDictionary = [NSMutableDictionary dictionary];

    NSArray * allCertificatesArray = [SAMKeychain accountsForService:kOTRCertificateServiceName];
    
    
    if ([allCertificatesArray count]) {
        [allCertificatesArray enumerateObjectsUsingBlock:^(NSDictionary * keychainProperties, NSUInteger idx, BOOL *stop) {
            
            NSString * domain = keychainProperties[kSAMKeychainAccountKey];
            NSArray * certs = [self storedCertificatesWithHostName:domain];
            resultsDictionary[domain] = certs;
        }];
    }
    
    
    return resultsDictionary;

}

+ (SAMKeychainQuery *)keychainQueryForHostName:(NSString *)hostname {
    SAMKeychainQuery * keychainQuery = [[SAMKeychainQuery alloc] init];
    keychainQuery.service = kOTRCertificateServiceName;
    keychainQuery.account = hostname;
    
    return keychainQuery;
}

+ (void)deleteAllCertificatesWithHostName:(NSString *)hostname {
    NSError * error = nil;
    [SAMKeychain deletePasswordForService:kOTRCertificateServiceName account:hostname error:&error];
    if (error) {
        DDLogError(@"Error deleting all certificates: %@", error);
    }
}
+ (void)deleteCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname {
    SAMKeychainQuery * keychainQuery = [self keychainQueryForHostName:hostname];
    
    NSError * error = nil;
    
    [keychainQuery fetch:&error];
    
    NSArray * certArray = nil;
    id passwordObject = keychainQuery.passwordObject;
    if ([passwordObject isKindOfClass:[NSArray class]]) {
        certArray = (NSArray *)passwordObject;
    }
    
    NSMutableArray * result = [NSMutableArray array];
    [certArray enumerateObjectsUsingBlock:^(NSData * certData, NSUInteger idx, BOOL *stop) {
        if (![certData isEqualToData:[OTRCertificatePinning dataForCertificate:cert]]) {
            [result addObject:certData];
        }
    }];
    if ([result count]) {
        keychainQuery.passwordObject = [NSArray arrayWithArray:result];
        error = nil;
        [keychainQuery save:&error];
        
        
    }
    else {
        [keychainQuery deleteItem:&error];
    }
    if (error) {
        DDLogError(@"Error saving cert to keychain: %@", error);
    }
}

+ (id)publicKeyWithCertData:(NSData *)certData
{
    if([certData length]) {
        return AFPublicKeyForCertificate(certData);
    }
    return nil;
}



/**
 * GCDAsyncSocket Delegate Methods
**/
#pragma - mark GCDAsyncSockeTDelegate Methods

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL))completionHandler
{
    NSString *hostName = sender.myJID.domain;
    // We should have a hostName. If we don't, something is wrong.
    NSParameterAssert(hostName.length > 0);
    if (!hostName.length) {
        completionHandler(NO);
    }
    BOOL trusted = [self isValidPinnedTrust:trust withHostName:hostName];
    if (!trusted) {
        //Delegate firing off for user to verify with status
        SecTrustResultType result;
        SecPolicyRef policy = SecPolicyCreateSSL(true, (__bridge CFStringRef)hostName);
        SecTrustSetPolicies(trust, policy);
        OSStatus status =  SecTrustEvaluate(trust, &result);
        CFRelease(policy);
        if ([self.delegate respondsToSelector:@selector(newTrust:withHostName:systemTrustResult:)] && status == noErr) {
            [self.delegate newTrust:trust withHostName:hostName systemTrustResult:result];
        }
    }
    completionHandler(trusted);
}




@end
