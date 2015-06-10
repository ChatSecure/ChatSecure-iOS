//
//  OTRAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"
#import "SSKeychain.h"
#import "OTRLog.h"
#import "OTRConstants.h"

#import "OTRXMPPAccount.h"
#import "OTRXMPPTorAccount.h"
#import "OTRGoogleOAuthXMPPAccount.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRBuddy.h"
#import "OTRImages.h"

NSString *const OTRAimImageName               = @"aim.png";
NSString *const OTRGoogleTalkImageName        = @"gtalk.png";
NSString *const OTRXMPPImageName              = @"xmpp.png";
NSString *const OTRXMPPTorImageName           = @"xmpp-tor-logo.png";

@interface OTRAccount ()

//@property (nonatomic) OTRAccountType accountType;

@end

@implementation OTRAccount

@synthesize accountType = _accountType;

- (id)init
{
    if(self = [super init])
    {
        _accountType = OTRAccountTypeNone;
    }
    return self;
}

- (id)initWithAccountType:(OTRAccountType)acctType
{
    if (self = [self init]) {
        
        _accountType = acctType;
    }
    return self;
}

- (OTRProtocolType)protocolType
{
    return OTRProtocolTypeNone;
}

- (UIImage *)accountImage
{
    return nil;
}

- (NSString *)accountDisplayName
{
    return @"";
}

- (NSString *)protocolTypeString
{
    return @"";
}

- (void)setAvatarData:(NSData *)avatarData
{
    if (![self.avatarData isEqualToData:avatarData]) {
        _avatarData = avatarData;
        [OTRImages removeImageWithIdentifier:self.uniqueId];
    }
}

- (UIImage *)avatarImage
{
    //on setAvatar clear this buddies image cache
    //invalidate if jid or display name changes
    return [OTRImages avatarImageWithUniqueIdentifier:self.uniqueId avatarData:self.avatarData displayName:self.displayName username:self.username];
}

- (Class)protocolClass {
    return nil;
}

- (void)setPassword:(NSString *) password {
    
    if (!password.length || !self.rememberPassword) {
        NSError *error = nil;
        [SSKeychain deletePasswordForService:kOTRServiceName account:self.uniqueId error:&error];
        if (error) {
            DDLogError(@"Error deleting password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        }
        return;
    }
    NSError *error = nil;
    [SSKeychain setPassword:password forService:kOTRServiceName account:self.uniqueId error:&error];
    if (error) {
        DDLogError(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
    }
}

- (NSString *)password {
    if (!self.rememberPassword) {
        return nil;
    }
    NSError *error = nil;
    NSString *password = [SSKeychain passwordForService:kOTRServiceName account:self.uniqueId error:&error];
    if (error) {
        DDLogError(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
        error = nil;
    }
    return password;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@",NSStringFromClass([self class]), self.username];
}

- (NSArray *)allBuddiesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSMutableArray *allBuddies = [NSMutableArray array];
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyEdges.account destinationKey:self.uniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (buddy) {
            [allBuddies addObject:buddy];
        }
    }];
    return allBuddies;
}


#pragma mark NSCoding

#pragma - mark Class Methods

+(OTRAccount *)accountForAccountType:(OTRAccountType)accountType
{
    OTRAccount *account = nil;
    if (accountType == OTRAccountTypeJabber) {
        account = [[OTRXMPPAccount alloc] initWithAccountType:accountType];
    }
    else if (accountType == OTRAccountTypeXMPPTor) {
        account = [[OTRXMPPTorAccount alloc] initWithAccountType:accountType];
    }
    else if (accountType == OTRAccountTypeGoogleTalk) {
        account = [[OTRGoogleOAuthXMPPAccount alloc] initWithAccountType:accountType];
    }
    
    return account;
}

+ (NSArray *)allAccountsWithUsername:(NSString *)username transaction:(YapDatabaseReadTransaction*)transaction
{
    __block NSMutableArray *accountsArray = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[OTRAccount collection] usingBlock:^(NSString *key, OTRAccount *account, BOOL *stop) {
        if ([account isKindOfClass:[OTRAccount class]] && [account.username isEqualToString:username]) {
            [accountsArray addObject:account];
        }
    }];
    return accountsArray;
}

+ (NSArray *)allAccountsWithTransaction:(YapDatabaseReadTransaction*)transaction
{
    NSMutableArray *accounts = [NSMutableArray array];
    NSArray *allAccountKeys = [transaction allKeysInCollection:[OTRAccount collection]];
    [allAccountKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [accounts addObject:[[transaction objectForKey:obj inCollection:[OTRAccount collection]]copy]];
    }];
    
    return accounts;
    
}

+ (NSUInteger)removeAllAccountsOfType:(OTRAccountType)accountType inTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSMutableArray *keys = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[self collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
        if ([object isKindOfClass:[self class]]) {
            OTRAccount *account = (OTRAccount *)object;
            account.password = nil;
            
            if (account.accountType == accountType) {
                [keys addObject:account.uniqueId];
            }
        }
    }];
    
    [transaction removeObjectsForKeys:keys inCollection:[self collection]];
    return [keys count];
}


// See MTLModel+NSCoding.h
// This helps enforce that only the properties keys that we
// desire will be encoded. Be careful to ensure that values
// that should be stored in the keychain don't accidentally
// get serialized!
+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *behaviors = [NSMutableDictionary dictionaryWithDictionary:[super encodingBehaviorsByPropertyKey]];
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(password))];
    return behaviors;
}

@end
