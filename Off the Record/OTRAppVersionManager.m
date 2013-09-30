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

@implementation OTRAppVersionManager


-(void)applyUpdatesForAppVersion:(NSString *)appVersionString
{
    NSString * lastVersionString = [OTRAppVersionManager lastLaunchVersion];
    
    if ([lastVersionString isEqualToString:appVersionString]) {
        return;
    }
    
    if (![lastVersionString length]) {
        [self applyAll];
    }
    
    [OTRAppVersionManager saveCurrentAppVersion];
}

-(void)updatesToVersion21
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
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveOnlySelfAndWait];
        }
    };
        
    moveAccount(kOTRFacebookDomain);
    moveAccount(kOTRGoogleTalkDomain);
    
}

-(void)applyAll
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
    [[[self alloc] init] applyUpdatesForAppVersion:currentVersionString];
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
