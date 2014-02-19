//
//  OTRSSLCertificate.h
//  Off the Record
//
//  Created by David Chiles on 2/18/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRSSLCertificate : NSObject


@property (nonatomic, strong) NSData * data;

@property (nonatomic, strong, readonly) NSString * issuerOrganization;
@property (nonatomic, strong, readonly) NSString * issuerCommonName;
@property (nonatomic, strong, readonly) NSString * subjectOrganization;
@property (nonatomic, strong, readonly) NSString * subjectCommonName;
@property (nonatomic, strong, readonly) NSDate * notValidAfter;
@property (nonatomic, strong, readonly) NSDate * notValidBefore;
@property (nonatomic, strong, readonly) NSNumber * version;
@property (nonatomic, strong, readonly) NSString * serialNumber;
@property (nonatomic, strong, readonly) NSString * SHA1fingerprint;


+ (instancetype)SSLCertifcateWithData:(NSData *)data;

@end
