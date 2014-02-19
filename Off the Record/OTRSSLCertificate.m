//
//  OTRSSLCertificate.m
//  Off the Record
//
//  Created by David Chiles on 2/18/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRSSLCertificate.h"

#import <CommonCrypto/CommonDigest.h>
#import "openssl/x509.h"

static NSString *const organizationShortName = @"O";
static NSString *const commonNameShortName = @"CN";

@interface OTRSSLCertificate ()

@property (nonatomic) X509 *x509Certificate;

@property (nonatomic, strong) NSString * issuerOrganization;
@property (nonatomic, strong) NSString * issuerCommonName;
@property (nonatomic, strong) NSString * subjectOrganization;
@property (nonatomic, strong) NSString * subjectCommonName;
@property (nonatomic, strong) NSDate * notValidAfter;
@property (nonatomic, strong) NSDate * notValidBefore;
@property (nonatomic, strong) NSString * serialNumber;
@property (nonatomic, strong) NSString * SHA1fingerprint;
@property (nonatomic, strong) NSNumber * version;


@end

@implementation OTRSSLCertificate


- (void)setData:(NSData *)data
{
    if ([self.data isEqual: data]) {
        return;
    }
    [self willChangeValueForKey:NSStringFromSelector(@selector(data))];
    _data = data;
    const unsigned char *certificateDataBytes = (const unsigned char *)[_data bytes];
    self.x509Certificate = d2i_X509(NULL, &certificateDataBytes, [_data length]);
    
    [self didChangeValueForKey:NSStringFromSelector(@selector(data))];
}

- (NSDate *)notValidBefore
{
    if (_notValidBefore) {
        return _notValidBefore;
    }
    if (self.x509Certificate != NULL) {
        ASN1_TIME *notValidBeforeASN1 = X509_get_notBefore(self.x509Certificate);
        _notValidBefore = [self dateFromASN1Time:notValidBeforeASN1];
    }
    return _notValidBefore;
}

- (NSDate *)notValidAfter
{
    if (_notValidAfter) {
        return _notValidAfter;
    }
    
    if (self.x509Certificate != NULL) {
        ASN1_TIME *certificateExpiryASN1 = X509_get_notAfter(self.x509Certificate);
        _notValidAfter = [self dateFromASN1Time:certificateExpiryASN1];
    }
    return _notValidAfter;
}

- (NSDate *)dateFromASN1Time:(ASN1_TIME *)asn1Time
{
    if (asn1Time != NULL) {
        ASN1_GENERALIZEDTIME *certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(asn1Time, NULL);
        if (certificateExpiryASN1Generalized != NULL) {
            unsigned char *certificateExpiryData = ASN1_STRING_data(certificateExpiryASN1Generalized);
            
            // ASN1 generalized times look like this: "20131114230046Z"
            //                                format:  YYYYMMDDHHMMSS
            //                               indices:  01234567890123
            //                                                   1111
            // There are other formats (e.g. specifying partial seconds or
            // time zones) but this is good enough for our purposes since
            // we only use the date and not the time.
            
            NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
            NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];
            
            expiryDateComponents.year     = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
            expiryDateComponents.month    = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
            expiryDateComponents.day      = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
            expiryDateComponents.hour     = [[expiryTimeStr substringWithRange:NSMakeRange(8, 2)] intValue];
            expiryDateComponents.minute   = [[expiryTimeStr substringWithRange:NSMakeRange(10, 2)] intValue];
            expiryDateComponents.second   = [[expiryTimeStr substringWithRange:NSMakeRange(12, 2)] intValue];
            expiryDateComponents.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
            
            NSCalendar *calendar = [NSCalendar currentCalendar];
            return [calendar dateFromComponents:expiryDateComponents];
        }
    }
    return nil;
}

- (NSString *)subjectOrganization
{
    if (_subjectOrganization) {
        return _subjectOrganization;
    }
    
    if (self.x509Certificate != NULL) {
        X509_NAME * subjectX509Name = X509_get_subject_name(self.x509Certificate);
        
        _subjectOrganization = [self stringFromX509Name:subjectX509Name shortName:organizationShortName];
    }
    return _subjectOrganization;
}

- (NSString *)subjectCommonName
{
    if (_subjectCommonName) {
        return _subjectCommonName;
    }
    
    if (self.x509Certificate) {
        X509_NAME * subjectX509Name = X509_get_subject_name(self.x509Certificate);
        
        _subjectCommonName = [self stringFromX509Name:subjectX509Name shortName:commonNameShortName];
    }
    
    return _subjectCommonName;
}

- (NSString *)issuerOrganization
{
    if (_issuerOrganization) {
        return _issuerOrganization;
    }
    
    if (self.x509Certificate != NULL) {
        X509_NAME *issuerX509Name = X509_get_issuer_name(self.x509Certificate);
        
        _issuerOrganization = [self stringFromX509Name:issuerX509Name shortName:organizationShortName];
    }
    return _issuerOrganization;
}

- (NSString *)issuerCommonName
{
    if (_issuerCommonName) {
        return _issuerCommonName;
    }
    
    if (self.x509Certificate) {
        X509_NAME *issuerX509Name = X509_get_issuer_name(self.x509Certificate);
        
        _issuerCommonName = [self stringFromX509Name:issuerX509Name shortName:commonNameShortName];
    }
    return _issuerCommonName;
}

- (NSNumber *)version
{
    if (_version) {
        return _version;
    }
    
    if (self.x509Certificate) {
        int intVersion = X509_get_version(self.x509Certificate);
        
        _version = [NSNumber numberWithInt:intVersion];
        
    }
    return _version;
}

- (NSString *)serialNumber
{
    if (_serialNumber) {
        return _serialNumber;
    }
    
    if (self.x509Certificate) {
        ASN1_INTEGER *serial = X509_get_serialNumber(self.x509Certificate);
        BIGNUM *bnser = ASN1_INTEGER_to_BN(serial, NULL);
        char *asciiHex = BN_bn2hex(bnser);
        NSString *hexString = [NSString stringWithFormat:@"%s" , asciiHex];
        
        NSMutableArray *buffer = [NSMutableArray arrayWithCapacity:[hexString length]];
        for (int i = 2; i < [hexString length]; i+=2) {
            NSRange range;
            range.location = i-2;
            range.length = 2;
            [buffer addObject:[NSString stringWithFormat:@"%@", [hexString substringWithRange:range]]];
        }
        _serialNumber = [[buffer componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return _serialNumber;
}

- (NSString *)SHA1fingerprint
{
    if (_SHA1fingerprint) {
        return _SHA1fingerprint;
    }
    
    unsigned char sha1Buffer[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(self.data.bytes, self.data.length, sha1Buffer);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i)
    {
        [fingerprint appendFormat:@"%02x ",sha1Buffer[i]];
    }
    
    _SHA1fingerprint = [[fingerprint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] uppercaseString];
    return _SHA1fingerprint;
}

- (NSString *)stringFromX509Name:(X509_NAME *)x509Name shortName:(NSString *)shortName
{
    if (x509Name) {
        const char *shortChar=[shortName UTF8String];
        int nid = OBJ_txt2nid(shortChar); // organization
        int index = X509_NAME_get_index_by_NID(x509Name, nid, -1);
        
        X509_NAME_ENTRY *issuerNameEntry = X509_NAME_get_entry(x509Name, index);
        
        if (issuerNameEntry) {
            ASN1_STRING *issuerNameASN1 = X509_NAME_ENTRY_get_data(issuerNameEntry);
            
            return [self stringFromASN1String:issuerNameASN1];
        }
    }
    return nil;
}

- (NSString *)stringFromASN1String:(ASN1_STRING *)string
{
    unsigned char *name = ASN1_STRING_data(string);
    return [NSString stringWithUTF8String:(char *)name];
}

- (void)reset
{
    self.issuerOrganization = nil;
    self.issuerCommonName = nil;
    self.subjectOrganization = nil;
    self.subjectCommonName = nil;
    self.SHA1fingerprint = nil;
    self.serialNumber = nil;
    self.notValidBefore = nil;
    self.notValidAfter = nil;
    self.version = nil;
}

+ (instancetype)SSLCertifcateWithData:(NSData *)data
{
    OTRSSLCertificate * certificate = [[self alloc] init];
    certificate.data = data;
    return certificate;
}

@end
