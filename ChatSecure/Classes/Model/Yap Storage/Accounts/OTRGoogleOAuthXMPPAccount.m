//
//  OTRGoogleOAuthXMPPAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRGoogleOAuthXMPPAccount.h"
@import gtm_oauth2;
@import OTRAssets;
#import "OTRConstants.h"


NSString *const kOTRExpirationDateKey = @"kOTRExpirationDateKey";
NSString *const kOTRExpiresInKey      = @"expires_in";


@implementation OTRGoogleOAuthXMPPAccount

- (UIImage *)accountImage
{
    return [UIImage imageNamed:OTRGoogleTalkImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
}

-(NSString *)accessTokenString {
    return [self authToken].accessToken;
}

-(void)setOAuthTokenDictionary:(NSDictionary *)oAuthTokenDictionary
{
    if ([oAuthTokenDictionary count]) {
        NSMutableDictionary * mutableTokenDictionary = [oAuthTokenDictionary mutableCopy];
        NSNumber * expiresIn = [mutableTokenDictionary objectForKey:kOTRExpiresInKey];
        [mutableTokenDictionary removeObjectForKey:kOTRExpiresInKey];
        NSDate *date = nil;
        if (expiresIn) {
            unsigned long deltaSeconds = [expiresIn unsignedLongValue];
            if (deltaSeconds > 0) {
                date = [NSDate dateWithTimeIntervalSinceNow:deltaSeconds];
            }
        }
        if(date) {
            [mutableTokenDictionary setObject:date forKey:kOTRExpirationDateKey];
        }
        oAuthTokenDictionary = mutableTokenDictionary;
    }
    [super setOAuthTokenDictionary:oAuthTokenDictionary];
}

-(NSDictionary *)oAuthTokenDictionary
{
    NSMutableDictionary * mutableTokenDictionary = [[super oAuthTokenDictionary] mutableCopy];
    NSDate * expirationDate = [mutableTokenDictionary objectForKey:kOTRExpirationDateKey];
    
    NSTimeInterval timeInterval  = [expirationDate timeIntervalSinceDate:[NSDate date]];
    mutableTokenDictionary[kOTRExpiresInKey] = @(timeInterval);
    return mutableTokenDictionary;
}

-(GTMOAuth2Authentication *)authToken
{
    GTMOAuth2Authentication * auth = nil;
    NSDictionary * tokenDictionary = [self oAuthTokenDictionary];
    if ([tokenDictionary count]) {
        auth = [[GTMOAuth2Authentication alloc] init];
        [auth setParameters:[tokenDictionary mutableCopy]];
    } else {
        return nil;
    }
    auth.clientID = [OTRBranding googleAppId];
    auth.clientSecret = [OTRSecrets googleAppSecret];
    auth.scope = [OTRBranding googleAppScope];
    auth.tokenURL = [GTMOAuth2SignIn googleTokenURL];
    return auth;
}

- (id)accountSpecificToken
{
    return [self authToken];
}

- (void)setAccountSpecificToken:(id)accountSpecificToken
{
    if ([accountSpecificToken isKindOfClass:[GTMOAuth2Authentication class]]) {
        GTMOAuth2Authentication *token = (GTMOAuth2Authentication *)accountSpecificToken;
        [self setOAuthTokenDictionary:token.parameters];
    }
}

#pragma - mark Class Methods 

+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

@end
