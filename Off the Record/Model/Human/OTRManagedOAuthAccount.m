#import "OTRManagedOAuthAccount.h"
#import "SSKeychain.h"
#import "OTRConstants.h"

#import "OTRLog.h"

@interface OTRManagedOAuthAccount ()

// Private interface goes here.

@end

@implementation OTRManagedOAuthAccount



-(void)setPassword:(NSString *)password
{
    if(![password length])
    {
        [self setTokenDictionary:nil];
    }
}
-(NSString *)password
{
    return [self accessTokenString];
}

-(SSKeychainQuery *)baseKeychainQuery
{
    SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
    keychainQuery.service = kOTRServiceName;
    keychainQuery.account = self.uniqueIdentifier;
    return keychainQuery;
}

-(void)setTokenDictionary:(NSDictionary *)accessTokenDictionary
{
    if (![accessTokenDictionary count]) {
        [super setPassword:nil];
    }
    else {
        NSError *error = nil;
        
        SSKeychainQuery * keychainQuery = [self baseKeychainQuery];
        
        keychainQuery.passwordObject = accessTokenDictionary;
        
        [keychainQuery save:&error];
        
        if (error) {
            DDLogError(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
    }
}

- (NSDictionary *)tokenDictionary
{
    NSError * error = nil;
    NSDictionary *dictionary = nil;
    
    SSKeychainQuery * keychainQuery = [self baseKeychainQuery];
    [keychainQuery fetch:&error];
    
    if (error) {
        DDLogError(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        error = nil;
    }
    else {
        dictionary = (NSDictionary *)keychainQuery.passwordObject;
    }
    return dictionary;
}

-(NSString *)accessTokenString
{
    return @"";
}
-(void)refreshTokenIfNeeded:(void (^)(NSError *))completion
{
    completion(nil);
}
-(void)refreshToken:(void (^)(NSError *))completionBlock
{
    completionBlock(nil);
}

+(id)createWithXmppAccount:(OTRManagedXMPPAccount *)xmppAccount
{
    xmppAccount = [xmppAccount MR_inThreadContext];
    OTRManagedOAuthAccount * oAuthAccount = [self MR_createEntity];
    
    oAuthAccount.username = xmppAccount.username;
    oAuthAccount.protocol = xmppAccount.protocol;
    oAuthAccount.rememberPassword = xmppAccount.rememberPassword;
    oAuthAccount.uniqueIdentifier = xmppAccount.uniqueIdentifier;
    oAuthAccount.domain =xmppAccount.domain;
    oAuthAccount.port = xmppAccount.port;
    
    [xmppAccount.subscriptionRequests enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [oAuthAccount addSubscriptionRequestsObject:obj];
    }];
    
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    
    return oAuthAccount;
}
@end
