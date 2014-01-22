#import "OTRmanagedFacebookAccount.h"
#import "FBAccessTokenData.h"
#import "OTRFacebookSessionCachingStrategy.h"
#import "Strings.h"


@interface OTRManagedFacebookAccount ()

// Private interface goes here.

@end


@implementation OTRManagedFacebookAccount

-(OTRAccountType)accountType
{
    return OTRAccountTypeFacebook;
}
-(NSString *)imageName
{
    return OTRFacebookImageName;
}
-(NSString *)providerName
{
    return FACEBOOK_STRING;
}

-(void)refreshToken:(void (^)(NSError * error))completionBlock
{
    FBAccessTokenData * auth = [self authToken];
    OTRFacebookSessionCachingStrategy * tokenCaching = [OTRFacebookSessionCachingStrategy createWithTokenDictionary:[auth dictionary]];
    FBSession * session = [[FBSession alloc] initWithAppID:FACEBOOK_APP_ID permissions:@[@"xmpp_login"] urlSchemeSuffix:nil tokenCacheStrategy:tokenCaching];
    if (session) {
        [self setTokenDictionary:[session.accessTokenData dictionary]];
        completionBlock(nil);
    }
    else {
        completionBlock([NSError errorWithDomain:@"" code:101 userInfo:@{NSLocalizedDescriptionKey:@"Error Creating Session"}]);
    }
    
}

-(void)refreshTokenIfNeeded:(void (^)(NSError * error))completion
{
    [self refreshToken:completion];
}
-(NSString *)accessTokenString {
    return [self authToken].accessToken;
}


-(FBAccessTokenData *)authToken
{
    FBAccessTokenData * auth = nil;
    NSDictionary * tokenDictionary = [self tokenDictionary];
    if ([tokenDictionary count]) {
        auth = [FBAccessTokenData createTokenFromDictionary:tokenDictionary];
    }
    return auth;
}
@end
