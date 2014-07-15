//
//  OTRFacebookSessionCachingStrategy.m
//  Off the Record
//
//  Created by David on 9/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRFacebookSessionCachingStrategy.h"
#import "SSKeychain.h"
#import "OTRConstants.h"



@implementation OTRFacebookSessionCachingStrategy

@synthesize tokenDictionary;

- (id)initWithTokenDictionary:(NSDictionary *)newTokenDictionary
{
    if (self = [self init]) {
        self.tokenDictionary = newTokenDictionary;
    }
    return self;
}



-(void) cacheTokenInformation:(NSDictionary *)tokenInformation
{
    self.tokenDictionary = tokenInformation;
}

- (NSDictionary*)fetchTokenInformation
{
    return self.tokenDictionary;
}

-(void)clearToken
{
    self.tokenDictionary = nil;
}

+ (id)createWithTokenDictionary:(NSDictionary *)tokenDictionary
{
    return [[self alloc] initWithTokenDictionary:tokenDictionary];
}

@end
