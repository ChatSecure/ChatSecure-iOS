//
//  OTRUtilities.m
//  Off the Record
//
//  Created by David on 2/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRUtilities.h"
#import "OTRBuddy.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRAccount.h"
#import "OTRDatabaseManager.h"
@import Security;
@import XLForm;

#import "OTRLog.h"

@implementation OTRUtilities

+(NSString *)currentAppVersionString {
    NSString * version = [NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    return version;
}

+(void)saveCurrentAppVersion
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self currentAppVersionString] forKey:kOTRAppVersionKey];
    [defaults synchronize];
}

+(NSString *)lastLaunchVersion {
    NSString * version = [[NSUserDefaults standardUserDefaults] objectForKey:kOTRAppVersionKey];
    return version;
}

+(BOOL)isFirstLaunchOnCurrentVersion
{
    if (![[self currentAppVersionString] isEqualToString:[self lastLaunchVersion]]) {
        [self saveCurrentAppVersion];
        return YES;
    }
    return NO;
}

+(NSString *)stripHTML:(NSString *)string
{
    if (!string) {
        return nil;
    }
    NSRange range;
    NSString *finalString = [string copy];
    while ((range = [finalString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound) {
        finalString = [finalString stringByReplacingCharactersInRange:range withString:@""];
    }
    return finalString;
}

+(NSString *)uniqueString
{
    NSString *result = nil;
	
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	if (uuid)
	{
		result = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
		CFRelease(uuid);
	}
	
	return result;
}

+(void)deleteAllBuddiesAndMessages
{
    [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeAllObjectsInCollection:[OTRBuddy collection]];
        [transaction removeAllObjectsInCollection:[OTRBaseMessage collection]];
    }];
}

+ (void)deleteAccountsWithoutUsername
{
    [[OTRDatabaseManager sharedInstance].writeConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        NSMutableArray *deleteKeys = [NSMutableArray array];
        [transaction enumerateKeysAndObjectsInCollection:[OTRAccount collection] usingBlock:^(NSString *key, OTRAccount *account, BOOL *stop) {
            if (![account.username length]) {
                [deleteKeys addObject:key];
            }
        }];
        
        [transaction removeObjectsForKeys:deleteKeys inCollection:[OTRAccount collection]];
    }];
}

+(BOOL)dateInLast24Hours:(NSDate *)date
{
    if([date timeIntervalSinceNow] < (24*60*60))
    {
        return YES;
    }
    return NO;
    
}
+(BOOL)dateInLast7Days:(NSDate *)date
{
    if([date timeIntervalSinceNow] < (7*24*60*60))
    {
        return YES;
    }
    return NO;
}

+(NSArray *)cipherSuites
{
    
    NSMutableArray *cipherSuitesArray = [NSMutableArray array];
    size_t numCiphers = 0;
    OSStatus status;
    
    //Create SSL Context
    SSLContextRef sslContext = SSLCreateContext(kCFAllocatorDefault, kSSLClientSide, kSSLStreamType);
    
    //GEt number of Supported Ciphers
    status = SSLGetNumberSupportedCiphers(sslContext, &numCiphers);
    DDLogVerbose(@"SSLGetNumberSupportedCiphers result %d, count %d",(int)status, (int)numCiphers);
    SSLCipherSuite ciphers[numCiphers];
    
    //Get list of Supported Ciphers
    status = SSLGetSupportedCiphers(sslContext, ciphers, &numCiphers);
    DDLogVerbose(@"SSLGetSupportedCiphers result %d",(int)status);
    
    for (int index = 0; index < numCiphers; index++) {
        if ([self useCipher:ciphers[index]]) {
            NSNumber * cipher = [NSNumber numberWithUnsignedShort: ciphers[index]];
            [cipherSuitesArray addObject:cipher];
        }
    }
    CFRelease(sslContext);
    
    return cipherSuitesArray;
}

+(BOOL)useCipher:(SSLCipherSuite)cipherSuite {
    switch (cipherSuite) {
        case TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_RSA_WITH_AES_128_CBC_SHA:
        case TLS_DH_DSS_WITH_AES_128_CBC_SHA:
        case TLS_DH_RSA_WITH_AES_128_CBC_SHA:
        case TLS_DHE_DSS_WITH_AES_128_CBC_SHA:
        case TLS_DHE_RSA_WITH_AES_128_CBC_SHA:
        case TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA:
        case TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA:
        case TLS_ECDH_RSA_WITH_AES_128_CBC_SHA:
        case TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA:
        case TLS_RSA_WITH_AES_256_CBC_SHA:
        case TLS_DH_DSS_WITH_AES_256_CBC_SHA:
        case TLS_DH_RSA_WITH_AES_256_CBC_SHA:
        case TLS_DHE_DSS_WITH_AES_256_CBC_SHA:
        case TLS_DHE_RSA_WITH_AES_256_CBC_SHA:
        case TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA:
        case TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:
        case TLS_ECDH_RSA_WITH_AES_256_CBC_SHA:
        case TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:
        case TLS_RSA_WITH_AES_128_GCM_SHA256:
        case TLS_RSA_WITH_AES_256_GCM_SHA384:
        case TLS_DHE_RSA_WITH_AES_128_GCM_SHA256:
        case TLS_DHE_RSA_WITH_AES_256_GCM_SHA384:
        case TLS_DH_RSA_WITH_AES_128_GCM_SHA256:
        case TLS_DH_RSA_WITH_AES_256_GCM_SHA384:
        case TLS_DHE_DSS_WITH_AES_128_GCM_SHA256:
        case TLS_DHE_DSS_WITH_AES_256_GCM_SHA384:
        case TLS_DH_DSS_WITH_AES_128_GCM_SHA256:
        case TLS_DH_DSS_WITH_AES_256_GCM_SHA384:
        case TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:
        case TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384:
        case TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256:
        case TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384:
        case TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256:
        case TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384:
        case TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256:
        case TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384:
        case TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:
        case TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:
        case TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256:
        case TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384:
        case TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:
        case TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:
        case TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256:
        case TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384:
        case TLS_DHE_RSA_WITH_AES_128_CBC_SHA256:
        case TLS_DHE_RSA_WITH_AES_256_CBC_SHA256:
            return YES;
            
        default:
            return NO;
    }
}

+ (BOOL)currentiOSVersionHasSSLVulnerability
{
    if ((SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") && SYSTEM_VERSION_LESS_THAN(@"6.1.6"))||(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && SYSTEM_VERSION_LESS_THAN(@"7.0.6"))) {
        return YES;
    }
    return NO;
}

@end


