//
//  OTRUtilities.m
//  Off the Record
//
//  Created by David on 2/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRUtilities.h"
#import "OTRManagedBuddy.h"
#import "OTRManagedGroup.h"
#import <Security/SecureTransport.h>

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
    NSRange range;
    NSString *finalString = [string copy];
    while ((range = [finalString rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        finalString = [finalString stringByReplacingCharactersInRange:range withString:@""];
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
    //Delete all stored buddies
    NSArray * buddyArray = [OTRManagedBuddy MR_findAll];
    [buddyArray enumerateObjectsUsingBlock:^(OTRManagedBuddy * buddy, NSUInteger idx, BOOL *stop) {
        [buddy MR_deleteEntity];
    }];
    
    [OTRManagedBuddy MR_deleteAllMatchingPredicate:nil];
    //Delete all stored messages
    [OTRManagedMessageAndStatus MR_deleteAllMatchingPredicate:nil];
    //Delete all Groups
    [OTRManagedGroup MR_deleteAllMatchingPredicate:nil];
    
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
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
    DDLogVerbose(@"Get Number Supported Ciphers: %d",(int)status);
    SSLCipherSuite ciphers[numCiphers];
    
    //Get list of Supported Ciphers
    status =  SSLGetSupportedCiphers(sslContext, ciphers, &numCiphers);
    DDLogVerbose(@"Get Supported Ciphers: %d",(int)status);
    
    
    //NSMutableArray * discardedCiphers = [NSMutableArray array];
    for (int index = 0; index < numCiphers; index++) {
        if ([self useCipher:ciphers[index]]) {
            NSNumber * cipher = [NSNumber numberWithUnsignedShort: ciphers[index]];
            [cipherSuitesArray addObject:cipher];
        }/**
          * Used to detect discarded ciphers
        else {
            
            NSNumber * cipher = [NSNumber numberWithUnsignedShort: ciphers[index]];
            DDLogVerbose(@"Hex value is 0x%02x", (unsigned int) ciphers[index]);
            [discardedCiphers addObject:cipher];
        }*/
    }
    
    return cipherSuitesArray;
}

+(BOOL)useCipher:(SSLCipherSuite)cipherSuite {
    switch (cipherSuite) {
        case SSL_RSA_WITH_RC2_CBC_MD5:
        case SSL_RSA_WITH_3DES_EDE_CBC_SHA:
        case SSL_DH_DSS_WITH_3DES_EDE_CBC_SHA:
        case SSL_DH_RSA_WITH_3DES_EDE_CBC_SHA:
        case SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA:
        case SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA:
        case TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA:
        case SSL_RSA_WITH_RC4_128_MD5:
        case SSL_RSA_WITH_RC4_128_SHA:
        case TLS_ECDH_ECDSA_WITH_RC4_128_SHA:
        case TLS_ECDHE_ECDSA_WITH_RC4_128_SHA:
        case TLS_ECDH_RSA_WITH_RC4_128_SHA:
        case TLS_ECDHE_RSA_WITH_RC4_128_SHA:
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

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (BOOL)currentiOSVersionHasSSLVulnerability
{
    if ((SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") && SYSTEM_VERSION_LESS_THAN(@"6.1.6"))||(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && SYSTEM_VERSION_LESS_THAN(@"7.0.6"))) {
        return YES;
    }
    return NO;
}

@end


