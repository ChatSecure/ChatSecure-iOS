//
//  OTRCertificatePinning.m
//  Off the Record
//
//  Created by David Chiles on 12/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificatePinning.h"
#import <SSKeychain/SSKeychain.h>
#import "SSKeychainQuery.h"
#import "GCDAsyncSocket.h"
#import "AFSecurityPolicy.h"
#import "XMPPStream.h"
#import "XMPPJID.h"

#import <CommonCrypto/CommonDigest.h>

#import "OTRConstants.h"
#import "OTRLog.h"
#import "XMPPStream.h"


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

- (instancetype)initWithDefaultCertificates
{
    if (self = [super init]) {
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
        self.securityPolicy.validatesDomainName = NO;
        self.securityPolicy.validatesCertificateChain = NO;
        self.securityPolicy.allowInvalidCertificates = YES;
    }
    return self;
    
}

- (void)loadKeychainCertificatesWithHostName:(NSString *)hostname {
    
    NSArray * hostnameCertificatesArray = [OTRCertificatePinning storedCertificatesWithHostName:hostname];
    
    self.securityPolicy.pinnedCertificates = hostnameCertificatesArray;
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

+ (instancetype)defaultCertificates
{
    return [[self alloc] initWithDefaultCertificates];
}

+ (void)addCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname {
    
    NSData * certData = [OTRCertificatePinning dataForCertificate:cert];
    
    if ([hostname length] && [certData length]) {
        SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
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

+ (NSArray *)storedCertificatesWithHostName:(NSString *)hostname {
    NSArray * certificateArray = nil;
    
    SSKeychainQuery * keychainQuery = [self keychainQueryForHostName:hostname];
    
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

+(NSString*)sha1FingerprintForCertificate:(SecCertificateRef)certificate {
    NSData * certData = [self dataForCertificate:certificate];
    unsigned char sha1Buffer[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(certData.bytes, (CC_LONG)certData.length, sha1Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i)
    {
        [fingerprint appendFormat:@"%02x ",sha1Buffer[i]];
    }
    
    return [fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (NSDictionary *)allCertificates {
    NSMutableDictionary * resultsDictionary = [NSMutableDictionary dictionary];

    NSArray * allCertificatesArray = [SSKeychain accountsForService:kOTRCertificateServiceName];
    
    
    if ([allCertificatesArray count]) {
        [allCertificatesArray enumerateObjectsUsingBlock:^(NSDictionary * keychainProperties, NSUInteger idx, BOOL *stop) {
            
            NSString * domain = keychainProperties[kSSKeychainAccountKey];
            NSArray * certs = [self storedCertificatesWithHostName:domain];
            resultsDictionary[domain] = certs;
        }];
    }
    
    
    return resultsDictionary;

}

+ (SSKeychainQuery *)keychainQueryForHostName:(NSString *)hostname {
    SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
    keychainQuery.service = kOTRCertificateServiceName;
    keychainQuery.account = hostname;
    
    return keychainQuery;
}

+ (void)deleteAllCertificatesWithHostName:(NSString *)hostname {
    NSError * error = nil;
    [SSKeychain deletePasswordForService:kOTRCertificateServiceName account:hostname error:&error];
    if (error) {
        DDLogError(@"Error deleting all certificates: %@", error);
    }
}
+ (void)deleteCertificate:(SecCertificateRef)cert withHostName:(NSString *)hostname {
    SSKeychainQuery * keychainQuery = [self keychainQueryForHostName:hostname];
    
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

+ (NSDictionary *)bundledCertHashes
{
    static NSDictionary *bundledCertHashes = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundledCertHashes = @{@"talk.google.com": @"83 56 59 a4 b0 02 c0 4b 37 91 70 59 70 e5 f7 95 ee 66 a1 70",
                              @"chat.facebook.com": @"21 f1 6b d6 61 95 d5 b4 3a 06 b4 e9 a0 50 7e 15 30 56 2e d3"};
    });
    return bundledCertHashes;
}

+ (void)loadBundledCertificatesToKeychain
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];
    
    NSMutableDictionary *certificates = [NSMutableDictionary dictionaryWithCapacity:[paths count]];
    for (NSString *path in paths) {
        NSData *certificateData = [NSData dataWithContentsOfFile:path];
        [certificates setObject:certificateData forKey:[[path lastPathComponent] stringByDeletingPathExtension]];
    }
    
    NSDictionary *bundledCertificatesDictionary = [NSDictionary dictionaryWithDictionary:certificates];
    
    [bundledCertificatesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *domain, NSData *bundledCertData, BOOL *stop) {
        
        NSString *hash = [self sha1FingerprintForCertificate:[self certForData:bundledCertData]];
        if ([hash isEqualToString:[self bundledCertHashes][domain]]) {
            [self addCertificate:[self certForData:bundledCertData] withHostName:domain];
        }
    }];
    
}



/**
 * GCDAsyncSocket Delegate Methods
**/
#pragma - mark GCDAsyncSockeTDelegate Methods

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL))completionHandler
{
    BOOL trusted = [self isValidPinnedTrust:trust withHostName:xmppStream.connectedHostName];
    if (!trusted) {
        //Delegate firing off for user to verify with status
        SecTrustResultType result;
        OSStatus status =  SecTrustEvaluate(trust, &result);
        if ([self.delegate respondsToSelector:@selector(newTrust:withHostName:systemTrustResult:)] && status == noErr) {
            [self.delegate newTrust:trust withHostName:xmppStream.connectedHostName systemTrustResult:result];
        }
    }
    completionHandler(trusted);
}




@end
