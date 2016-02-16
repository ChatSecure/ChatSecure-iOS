//
//  OTROAuthXMPPAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTROAuthXMPPAccount.h"
#import <SSKeychain/SSKeychain.h>
#import "OTRLog.h"
#import "OTRConstants.h"

@implementation OTROAuthXMPPAccount

-(void)setPassword:(NSString *)password
{
    if(![password length])
    {
        [self setOAuthTokenDictionary:nil];
    }
}
-(NSString *)password
{
    return [self accessTokenString];
}

-(NSString *)accessTokenString
{
    return @"";
}

-(void)setOAuthTokenDictionary:(NSDictionary *)oAuthTokenDictionary
{
    if (![oAuthTokenDictionary count]) {
        [super setPassword:nil];
    }
    else {
        NSError *error = nil;
        
        SSKeychainQuery * keychainQuery = [self baseKeychainQuery];
        
        keychainQuery.passwordObject = oAuthTokenDictionary;
        
        [keychainQuery save:&error];
        
        if (error) {
            DDLogError(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
    }
}

- (NSDictionary *)oAuthTokenDictionary
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

-(SSKeychainQuery *)baseKeychainQuery
{
    SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
    keychainQuery.service = kOTRServiceName;
    keychainQuery.account = self.uniqueId;
    return keychainQuery;
}


#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

+ (NSDictionary*) encodingBehaviorsByPropertyKey {
    NSMutableDictionary *encodingBehaviors = [NSMutableDictionary dictionaryWithDictionary:[super encodingBehaviorsByPropertyKey]];
    [encodingBehaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(accountSpecificToken))];
    [encodingBehaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(oAuthTokenDictionary))];
    return encodingBehaviors;
}

@end
