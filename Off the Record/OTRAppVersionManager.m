//
//  OTRAppVersionManager.m
//  Off the Record
//
//  Created by David on 9/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRAppVersionManager.h"
#import "OTRConstants.h"
#import "OTRAccountsManager.h"
#import "OTRManagedXMPPAccount.h"
#import "OTRManagedFacebookAccount.h"
#import "OTRManagedGoogleAccount.h"
#import "SSKeychain.h"

@implementation OTRAppVersionManager


+(void)applyUpdatesForAppVersion:(NSString *)appVersionString
{
    NSString * lastVersionString = [OTRAppVersionManager lastLaunchVersion];
    
    if ([lastVersionString isEqualToString:appVersionString]) {
        return;
    }
    
    if (![lastVersionString length]) {
        [self applyAll];
    }
    else if ([lastVersionString isEqualToString:@"2.1"] || [lastVersionString isEqualToString:@"2.1.1"] || [lastVersionString isEqualToString:@"2.1.2"])
    {
        [self updatesToVersion22];
    }
    
    [OTRAppVersionManager saveCurrentAppVersion];
}

+(void)updatesToVersion22
{
    //use old method for retrieving oauth dict then save it with new method
    NSArray * oAuthAccounts = [OTRManagedOAuthAccount MR_findAll];
    __block SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
    [oAuthAccounts enumerateObjectsUsingBlock:^(OTRManagedOAuthAccount * account, NSUInteger idx, BOOL *stop) {
        if (account.username) {
            NSError * error = nil;
            keychainQuery.service = kOTRServiceName;
            keychainQuery.account = account.username;
            if([keychainQuery fetch:&error])
            {
                NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:keychainQuery.passwordData];
                NSDictionary * dictionary = [unarchiver decodeObjectForKey:OTRArchiverKey];
                [unarchiver finishDecoding];
                [keychainQuery deleteItem:&error];
                keychainQuery.passwordObject = dictionary;
                [account setTokenDictionary:dictionary];
            }
        }
    }];
    NSArray * allAccounts = [OTRManagedAccount MR_findAll];
    [allAccounts enumerateObjectsUsingBlock:^(OTRManagedAccount * account, NSUInteger idx, BOOL *stop) {
        if (![account isKindOfClass:[OTRManagedOAuthAccount class]]) {
            NSString * password = [SSKeychain passwordForService:kOTRServiceName account:account.username];
            [SSKeychain deletePasswordForService:kOTRServiceName account:account.username];
            [account setPassword:password];
        }
        
    }];
}

+(void)updatesToVersion21
{
    [OTRAppVersionManager removeAllPasswordsForAccountType:OTRAccountTypeFacebook];
    [OTRAppVersionManager removeAllPasswordsForAccountType:OTRAccountTypeGoogleTalk];
        
    void (^moveAccount)(NSString * domain) = ^void(NSString * domain) {
        if ([domain length]) {
            NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K MATCHES[cd] %@",OTRManagedXMPPAccountAttributes.domain,domain];
            NSArray * accounts = [OTRManagedXMPPAccount MR_findAllWithPredicate:predicate];
            [accounts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                OTRManagedXMPPAccount * account = obj;
                if (account.accountType == OTRAccountTypeJabber) {
                    if([domain isEqualToString:kOTRFacebookDomain]) {
                        [OTRManagedFacebookAccount createWithXmppAccount:account];
                        [account MR_deleteEntity];
                    }
                    else if([domain isEqualToString:kOTRGoogleTalkDomain]) {
                        [OTRManagedGoogleAccount createWithXmppAccount:account];
                        [account MR_deleteEntity];
                    }
                }
            }];
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
        }
    };
        
    moveAccount(kOTRFacebookDomain);
    moveAccount(kOTRGoogleTalkDomain);
    
}

+(void)applyAll
{
    [self updatesToVersion21];
}

+(NSString *)currentAppVersionString {
    NSString * version = [NSString stringWithFormat:@"%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    return version;
}

+(void)saveCurrentAppVersion
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self currentAppVersionString] forKey:kOTRAppVersionKey];
    [defaults synchronize];
}

+(NSString *)lastLaunchVersion {
    NSString * version = [[NSUserDefaults standardUserDefaults] objectForKey:kOTRAppVersionKey];
    return version;
}

+(void)applyAppUpdatesForCurrentAppVersion
{
    NSString * currentVersionString = [OTRAppVersionManager currentAppVersionString];
    [self applyUpdatesForAppVersion:currentVersionString];
}


+ (void)removeAllPasswordsForAccountType:(OTRAccountType)accountType
{
    NSString * domain = nil;
    if (accountType == OTRAccountTypeFacebook) {
        domain = kOTRFacebookDomain;
    }
    else if (accountType == OTRAccountTypeGoogleTalk) {
        domain = kOTRGoogleTalkDomain;
    }
    
    if ([domain length]) {
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K MATCHES[cd] %@",OTRManagedXMPPAccountAttributes.domain,domain];
        NSArray * accounts = [OTRManagedXMPPAccount MR_findAllWithPredicate:predicate];
        [accounts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            OTRManagedAccount * account = obj;
            if (account.accountType == OTRAccountTypeJabber) {
                [account setPassword:nil];
            }
        }];
    }
}


@end
