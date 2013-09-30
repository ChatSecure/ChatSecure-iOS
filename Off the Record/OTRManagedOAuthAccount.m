#import "OTRManagedOAuthAccount.h"
#import "SSKeychain.h"
#import "OTRConstants.h"

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

-(void)setTokenDictionary:(NSDictionary *)accessTokenDictionary
{
    if (![accessTokenDictionary count]) {
        [super setPassword:nil];
    }
    else {
        NSError *error = nil;
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:accessTokenDictionary forKey:OTRArchiverKey];
        [archiver finishEncoding];
        [SSKeychain setPasswordData:data forService:kOTRServiceName account:self.username error:&error];
        if (error) {
            NSLog(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
    }
}

- (NSDictionary *)tokenDictionary
{
    NSError * error = nil;
    NSDictionary *dictionary = nil;
    NSData * data = [SSKeychain passwordDataForService:kOTRServiceName account:self.username error:&error];
    if (error) {
        NSLog(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        error = nil;
    }
    else {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        dictionary = [unarchiver decodeObjectForKey:OTRArchiverKey];
        [unarchiver finishDecoding];
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
    oAuthAccount.allowPlainTextAuthentication = xmppAccount.allowPlainTextAuthentication;
    oAuthAccount.allowSelfSignedSSL = xmppAccount.allowSelfSignedSSL;
    oAuthAccount.allowSSLHostNameMismatch = xmppAccount.allowSSLHostNameMismatch;
    oAuthAccount.domain =xmppAccount.domain;
    oAuthAccount.port = xmppAccount.port;
    oAuthAccount.requireTLS = xmppAccount.requireTLS;
    oAuthAccount.sendDeliveryReceipts = xmppAccount.sendDeliveryReceipts;
    oAuthAccount.sendTypingNotifications = xmppAccount.sendTypingNotifications;
    
    [xmppAccount.subscriptionRequests enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [oAuthAccount addSubscriptionRequestsObject:obj];
    }];
    
    return oAuthAccount;
}
@end
