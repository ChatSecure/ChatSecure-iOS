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
#import "OTRLog.h"

#define keychainKeyPrefix @"sslcert."
#define keychainDictionaryKey @"keychainDictionaryKey"

@implementation OTRCertificatePinning

- (id)initWithDefaultCertificates
{
    if (self = [super init]) {
        self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        self.doNotManuallyEvaluateOverride = NO;
        //[self loadKeychainCertificates];
    }
    return self;
    
}

- (void)loadKeychainCertificatesWithHostName:(NSString *)hostname {
    self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    NSArray * allCertificatesArray = [self.securityPolicy.pinnedCertificates arrayByAddingObjectsFromArray:[self storedCertificatesWithHostName:hostname]];
    
    self.securityPolicy.pinnedCertificates = allCertificatesArray;
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
                DDLogError(@"Error saving new certificate to keychain");
            }
        }
        
        
        

    }
}

-(NSArray *)storedCertificatesWithHostName:(NSString *)hostname {
    return [OTRCertificatePinning storedCertificatesWithHostName:hostname];
}

+(NSDictionary *)bundledCertificateFileNames {
    return @{@"talk.google.com":@"google",@"chat.facebook.com":@"facebook"};
}

+ (NSArray *)storedCertificatesWithHostName:(NSString *)hostname {
    NSArray * certificateArray = nil;
    
    SSKeychainQuery * keychainQuery = [self keychainQueryForHostName:hostname];
    
    NSError * error =nil;
    [keychainQuery fetch:&error];
    
    if (error) {
        DDLogError(@"Error retrieving certificates from keychain");
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

+ (NSDictionary *)bundledCertificates {
    NSMutableDictionary * certDict = [NSMutableDictionary dictionary];
    [[self bundledCertificateFileNames] enumerateKeysAndObjectsUsingBlock:^(NSString * domain, NSString * filename, BOOL *stop) {
        NSString * path = [[NSBundle mainBundle] pathForResource:filename ofType:@"cer"];
        NSData * certData = [NSData dataWithContentsOfFile:path];
        certDict[domain] = @[certData];
    }];
    return certDict;
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
        DDLogError(@"Error deleting all certificates");
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
        DDLogError(@"Error saving cert to keychain");
    }
}

/**
 * GCDAsyncSocket Delegates
**/
- (BOOL)socket:(GCDAsyncSocket *)sock shouldFinishConnectionWithTrust:(SecTrustRef)trust status:(OSStatus)status {
    
    BOOL trusted = [self isValidPinnedTrust:trust withHostName:xmppStream.connectedHostName];
    if (!trusted) {
        //Delegate firing off for user to verify with status
        if ([self.delegate respondsToSelector:@selector(newTrust:withHostName:withStatus:)]) {
            [self.delegate newTrust:trust withHostName:xmppStream.connectedHostName withStatus:status];
        }
    }
    
    return trusted;
}

- (BOOL)socketShouldManuallyEvaluateTrust:(GCDAsyncSocket *)sock {
    if (self.doNotManuallyEvaluateOverride) {
        self.doNotManuallyEvaluateOverride = NO;
        return NO;
    }
    
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
    BOOL trusted = [self isValidPinnedTrust:trust withHostName:xmppStream.connectedHostName];
    if (!trusted) {
        //Delegate firing off for user to verify with status
        if ([self.delegate respondsToSelector:@selector(newTrust:withHostName:withStatus:)]) {
            [self.delegate newTrust:trust withHostName:xmppStream.connectedHostName withStatus:errSSLPeerAuthCompleted];
        }
    }
    return trusted;
}


@end
