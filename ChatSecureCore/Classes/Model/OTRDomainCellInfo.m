//
//  OTRDomainCellInfo.m
//  ChatSecure
//
//  Created by David Chiles on 10/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDomainCellInfo.h"

@interface OTRDomainCellInfo ()

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *usernameDomain;

@end

@implementation OTRDomainCellInfo

- (instancetype) initWithDisplayName:(NSString *)displayName usernameDomain:(NSString *)usernameDomain domain:(NSString *)domain
{
    if (self = [self init]) {
        
        self.domain = domain;
        
        if ([displayName length]) {
            self.displayName = displayName;
        } else {
            self.displayName = domain;
        }
        
        if ([usernameDomain length]) {
            self.usernameDomain = usernameDomain;
        } else {
            self.usernameDomain = domain;
        }
        
        
    }
    return self;
}

+ (instancetype) domainCellInfoWithDisplayName:(NSString *)displayName usernameDomain:(NSString *)usernameDomain domain:(NSString *)domain
{
    return [[self alloc] initWithDisplayName:displayName usernameDomain:usernameDomain domain:domain];
}

+ (NSArray *)defaultDomainCellInfoArray
{
    return @[[self domainCellInfoWithDisplayName:@"Dukgo" usernameDomain:nil domain:@"dukgo.com"],
             [self domainCellInfoWithDisplayName:@"Chaos Computer Club" usernameDomain:nil domain:@"jabber.ccc.de"],
             [self domainCellInfoWithDisplayName:@"The Calyx Institute" usernameDomain:nil domain:@"jabber.calyxinstitute.org"],
             [self domainCellInfoWithDisplayName:nil usernameDomain:nil domain:@"jabberpl.org"],
             [self domainCellInfoWithDisplayName:nil usernameDomain:nil domain:@"rkquery.de"],
             [self domainCellInfoWithDisplayName:nil usernameDomain:nil domain:@"xmpp.jp"]
             ];
}
+ (NSArray *)defaultTorDomainCellInfoArray
{
    return @[
             [self domainCellInfoWithDisplayName:@"The Calyx Institute" usernameDomain:@"jabber.calyxinstitute.org" domain:@"ijeeynrc6x2uy5ob.onion"],
              [self domainCellInfoWithDisplayName:@"Chaos Computer Club" usernameDomain:@"jabber.ccc.de" domain:@"okj7xc6j2szr2y75.onion"],
             [self domainCellInfoWithDisplayName:@"Dukgo" usernameDomain:nil domain:@"dukgo.com"],
             [self domainCellInfoWithDisplayName:nil usernameDomain:nil domain:@"jabberpl.org"],
             [self domainCellInfoWithDisplayName:nil usernameDomain:nil domain:@"rkquery.de"],
             [self domainCellInfoWithDisplayName:nil usernameDomain:nil domain:@"xmpp.jp"]
             ];
}

@end
