//
//  OTRFacebookOAuthXMPPAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRFacebookOAuthXMPPAccount.h"
#import "OTRImages.h"
#import "Strings.h"
#import "FBAccessTokenData.h"
#import "OTRConstants.h"


@implementation OTRFacebookOAuthXMPPAccount

- (id)init
{
    if (self = [super init]) {
        self.domain = kOTRFacebookDomain;
    }
    return self;
}

- (UIImage *)accountImage
{
    return [OTRImages facebookImage];
}

- (NSString *)accountDisplayName
{
    return FACEBOOK_STRING;
}

-(NSString *)accessTokenString {
    return [self authToken].accessToken;
}

-(FBAccessTokenData *)authToken
{
    FBAccessTokenData * auth = nil;
    NSDictionary * tokenDictionary = [self oAuthTokenDictionary];
    if ([tokenDictionary count]) {
        auth = [FBAccessTokenData createTokenFromDictionary:tokenDictionary];
    }
    return auth;
}

- (id)accountSpecificToken
{
    return [self authToken];
}

- (void)setAccountSpecificToken:(id)accountSpecificToken
{
    if ([accountSpecificToken isKindOfClass:[FBAccessTokenData class]]) {
        [self setOAuthTokenDictionary:((FBAccessTokenData *)accountSpecificToken).dictionary];
    }
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

@end
