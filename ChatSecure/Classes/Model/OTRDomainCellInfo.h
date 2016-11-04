//
//  OTRDomainCellInfo.h
//  ChatSecure
//
//  Created by David Chiles on 10/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

@interface OTRDomainCellInfo : NSObject

//Better display name for the server or orginization
@property (nonatomic, strong, readonly) NSString *displayName;

//The domain that should be appended to the username may differ from domain in some cases such as TOR
@property (nonatomic, strong, readonly) NSString *usernameDomain;

//The server domain to connect to
@property (nonatomic, strong, readonly) NSString *domain;


+ (instancetype) domainCellInfoWithDisplayName:(NSString *)displayName usernameDomain:(NSString *)usernameDomain domain:(NSString *)domain;

+ (NSArray *)defaultDomainCellInfoArray;
+ (NSArray *)defaultTorDomainCellInfoArray;

@end
