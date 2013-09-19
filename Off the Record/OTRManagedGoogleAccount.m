#import "OTRManagedGoogleAccount.h"
#import "GTMOAuth2Authentication.h"

@interface OTRManagedGoogleAccount ()

// Private interface goes here.

@end


@implementation OTRManagedGoogleAccount

-(void)refreshToken:(void (^)(NSError *error))completionBlock
{
    [[self authToken] authorizeRequest:nil completionHandler:completionBlock];
}

-(void)refreshTokenIfNeeded:(void (^)(NSError *error))completion
{
    if ([self needsRefresh] ) {
        [self refreshToken:completion];
    }
    else {
        completion(nil);
    }
}

-(NSString *)accessTokenString {
    return [self authToken].accessToken;
}

-(BOOL)needsRefresh
{
    GTMOAuth2Authentication * auth = [self authToken];
    BOOL shouldRefresh = NO;
    if ([auth.refreshToken length] || [auth.assertion length] || [auth.code length]) {
        if (![auth.accessToken length]) {
            shouldRefresh = YES;
        } else {
            // We'll consider the token expired if it expires 60 seconds from now
            // or earlier
            
            /////Dumb google needs to refesh expirationDate
            [auth setExpiresIn:auth.expiresIn];
            /////////
            
            NSDate *expirationDate = auth.expirationDate;
            NSTimeInterval timeToExpire = [expirationDate timeIntervalSinceNow];
            if (expirationDate == nil || timeToExpire < 60.0) {
                // access token has expired, or will in a few seconds
                shouldRefresh = YES;
            }
        }
    }
    return shouldRefresh;
}

-(GTMOAuth2Authentication *)authToken
{
    GTMOAuth2Authentication * auth = nil;
    NSDictionary * tokenDictionary = [self tokenDictionary];
    if ([tokenDictionary count]) {
        auth = [[GTMOAuth2Authentication alloc] init];
        [auth setParameters:[tokenDictionary mutableCopy]];
    }
    return auth;
}

@end
