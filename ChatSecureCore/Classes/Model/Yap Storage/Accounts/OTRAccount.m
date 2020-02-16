//
//  OTRAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"
@import SAMKeychain;
#import "OTRLog.h"
#import "OTRConstants.h"

#import "OTRXMPPAccount.h"
#import "OTRXMPPTorAccount.h"
#import "OTRDatabaseManager.h"
@import YapDatabase;
#import "OTRBuddy.h"
#import "OTRImages.h"
#import "NSURL+ChatSecure.h"
#import "OTRProtocolManager.h"
#import "ChatSecureCoreCompat-Swift.h"
#import "OTRColors.h"


NSString *const OTRAimImageName               = @"aim.png";
NSString *const OTRGoogleTalkImageName        = @"gtalk.png";
NSString *const OTRXMPPImageName              = @"xmpp.png";
NSString *const OTRXMPPTorImageName           = @"xmpp-tor-logo.png";

@interface OTRAccount ()
@end

@implementation OTRAccount
@dynamic isArchived;
@synthesize accountType = _accountType;
/** This value is only used when rememberPassword is false */
@synthesize password = _password;

- (void) dealloc {
    if (!self.rememberPassword) {
        [self removeKeychainPassword:nil];
    }
}

- (nullable instancetype)initWithUsername:(NSString*)username
                              accountType:(OTRAccountType)accountType {
    NSParameterAssert(username != nil);
    NSParameterAssert([self class] == [[self class] accountClassForAccountType:accountType]);
    if (!username) {
        return nil;
    }
    if ([self class] != [[self class] accountClassForAccountType:accountType]) {
        return nil;
    }
    if (self = [super init]) {
        _username = [username copy];
        _accountType = accountType;
    }
    return self;
}

+ (nullable Class) accountClassForAccountType:(OTRAccountType)accountType {
    switch(accountType) {
        case OTRAccountTypeJabber:
            return [OTRXMPPAccount class];
        case OTRAccountTypeXMPPTor:
            return [OTRXMPPTorAccount class];
        default:
            return nil;
    }
}

- (OTRProtocolType)protocolType
{
    switch(self.accountType) {
        case OTRAccountTypeGoogleTalk:
        case OTRAccountTypeJabber:
        case OTRAccountTypeXMPPTor:
            return OTRProtocolTypeXMPP;
        default:
            return OTRProtocolTypeNone;
    }
    return OTRProtocolTypeNone;
}

- (UIImage *)accountImage
{
    return nil;
}

- (NSString *)protocolTypeString
{
    switch(self.protocolType) {
        case OTRProtocolTypeXMPP:
            return kOTRProtocolTypeXMPP;
        default:
            return @"";
    }
    return @"";
}

- (NSString*) displayName {
    // If user has set a displayName that isn't the JID, use that immediately
    if (_displayName.length > 0 && ![_displayName isEqualToString:self.username]) {
        return _displayName;
    }
    NSString *user = [self.username otr_displayName];
    if (!user.length) {
        return _displayName;
    }
    return user;
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

- (UIColor *)avatarBorderColor {
    if ([[OTRProtocolManager sharedInstance] existsProtocolForAccount:self]) {
        OTRXMPPManager *xmpp = [OTRProtocolManager.shared xmppManagerForAccount:self];
        if (xmpp.loginStatus == OTRLoginStatusAuthenticated) {
            return [OTRColors colorWithStatus:OTRThreadStatusAvailable];
        }
    }
    return nil;
}

// Overridden in superclass
- (BOOL) isArchived {
    return NO;
}

- (Class)protocolClass {
    NSAssert(NO, @"Must implement in subclass.");
    return nil;
}

- (BOOL) removeKeychainPassword:(NSError**)error {
    NSError *internalError = nil;
    BOOL result = [SAMKeychain deletePasswordForService:kOTRServiceName account:self.uniqueId error:&internalError];
    if (!result) {
        DDLogError(@"Error deleting password from keychain: %@%@", [internalError localizedDescription], [internalError userInfo]);
    } else {
        DDLogInfo(@"Password for %@ deleted from keychain.", self.username);
    }
    if (error) {
        *error = internalError;
    }
    return result;
}

- (void)setPassword:(NSString *) password {
    // Store password in-memory only if rememberPassword is false
    // Also remove keychain value
    if (!self.rememberPassword) {
        [self removeKeychainPassword:nil];
        _password = password;
        return;
    }
    if (!password.length) {
        NSAssert(password.length > 0, @"Improperly removing password!");
        DDLogError(@"Improperly removing password! To remove password call removeKeychainPassword!");
        return;
    }
    NSError *error = nil;
    BOOL result = [SAMKeychain setPassword:password forService:kOTRServiceName account:self.uniqueId error:&error];
    if (!result) {
        DDLogError(@"Error saving password to keychain: %@%@", [error localizedDescription], [error userInfo]);
    }
}

- (NSString *)password {
    if (!self.rememberPassword) {
        [self removeKeychainPassword:nil];
        return _password;
    }
    NSError *error = nil;
    NSString *password = [SAMKeychain passwordForService:kOTRServiceName account:self.uniqueId error:&error];
    if (error) {
        //NSAssert(password.length > 0, @"Looking for password in keychain but it wasn't found!");
        DDLogError(@"Error retreiving password from keychain: %@%@", [error localizedDescription], [error userInfo]);
    }
    return password;
}

- (NSArray *)allBuddiesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSMutableArray *allBuddies = [NSMutableArray array];
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameBuddyAccountEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (buddy.username.length) {
            [allBuddies addObject:buddy];
        }
    }];
    return allBuddies;
}

+ (nullable instancetype) fetchObjectWithUniqueID:(NSString *)uniqueID transaction:(YapDatabaseReadTransaction *)transaction {
    if (!uniqueID || !transaction) { return nil; }
    OTRAccount *account = (OTRAccount*)[super fetchObjectWithUniqueID:uniqueID transaction:transaction];
    if (!account.username.length) {
        return nil;
    }
    return account;
}


#pragma mark NSCoding

#pragma - mark Class Methods

+ (nullable instancetype)accountWithUsername:(NSString*)username
                                 accountType:(OTRAccountType)accountType
{
    NSParameterAssert(username != nil);
    if (!username) { return nil; }
    Class accountClass = [self accountClassForAccountType:accountType];
    if (!accountClass) {
        return nil;
    }
    OTRAccount *account = [[accountClass alloc] initWithUsername:username accountType:accountType];
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
    if (accountsArray.count > 1) {
        DDLogWarn(@"More than one account matching username! %@ %@", username, accountsArray);
    }
    return accountsArray;
}

+ (NSUInteger) numberOfAccountsWithTransaction:(YapDatabaseReadTransaction*)transaction {
    return [transaction numberOfKeysInCollection:[OTRAccount collection]];
}

+ (nullable OTRAccount*) accountForThread:(id<OTRThreadOwner>)thread transaction:(YapDatabaseReadTransaction*)transaction {
    NSParameterAssert(thread);
    if (!thread) { return nil; }
    OTRAccount *account = [transaction objectForKey:[thread threadAccountIdentifier] inCollection:[OTRAccount collection]];
    return account;
}

+ (NSArray <OTRAccount *>*)allAccountsWithTransaction:(YapDatabaseReadTransaction*)transaction
{
    NSMutableArray <OTRAccount *>*accounts = [NSMutableArray array];
    NSString *collection = [OTRAccount collection];
    NSArray <NSString*>*allAccountKeys = [transaction allKeysInCollection:collection];
    [allAccountKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        id object = [transaction objectForKey:key inCollection:collection];
        if (object && [object isKindOfClass:[OTRAccount class]]) {
            [accounts addObject:object];
        }
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
    [behaviors setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(isArchived))];
    return behaviors;
}

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    if ([propertyKey isEqualToString:NSStringFromSelector(@selector(password))] || [propertyKey isEqualToString:NSStringFromSelector(@selector(isArchived))]) {
        return MTLPropertyStorageNone;
    }
    return [super storageBehaviorForPropertyWithKey:propertyKey];
}

#pragma mark Fingerprints

/**
 *  Returns the full share URL invite link for this account. Optionally includes fingerprints of various key types.
 *
 *  @param fingerprintTypes (optional) include a NSSet of boxed of OTRFingerprintType values
 *  @param completion called on main queue with shareURL, or potentially nil if there's an error during link generation.
 */
- (void) generateShareURLWithFingerprintTypes:(NSSet <NSNumber*> *)fingerprintTypes
                                   completion:(void (^)(NSURL* shareURL, NSError *error))completionBlock {
    NSParameterAssert(completionBlock != nil);
    if (!completionBlock) {
        return;
    }
    NSURL *baseURL = [NSURL otr_shareBaseURL];
    
    NSMutableDictionary <NSString*, NSString*> *fingerprints = [NSMutableDictionary dictionary];
    
    if (fingerprintTypes.count > 0) {
        // We only support OTR fingerprints at the moment
        if ([fingerprintTypes containsObject:@(OTRFingerprintTypeOTR)]) {
            [OTRProtocolManager.encryptionManager.otrKit generatePrivateKeyForAccountName:self.username protocol:self.protocolTypeString completion:^(OTRFingerprint * _Nullable fingerprint, NSError * _Nullable error) {
                
                if (fingerprint) {
                    NSString *key = [[self class] fingerprintStringTypeForFingerprintType:OTRFingerprintTypeOTR];
                    [fingerprints setObject:[fingerprint.fingerprint otr_hexString] forKey:key];
                }
                
                // Since we only support OTR at the moment, we can finish here, but this should be refactored with a dispatch_group when we support more key types.
                NSMutableArray <NSURLQueryItem*> *queryItems = [NSMutableArray arrayWithCapacity:fingerprints.count];
                [fingerprints enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                    NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:key value:obj];
                    [queryItems addObject:item];
                }];
                XMPPJID *jid = [XMPPJID jidWithString:self.username];
                NSURL *url = [NSURL otr_shareLink:baseURL jid:jid queryItems:queryItems];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(url, nil);
                });

                
            }];
        }
    }
}

/**
 *  Returns string representation of OTRFingerprintType
 *
 *  - "otr" for OTRFingerprintTypeOTR
 *  - "omemo" for OTRFingerprintTypeAxolotl
 *  - "gpg" for OTRFingerprintTypeGPG
 *
 *  @return String representation of OTRFingerprintType
 */
+ (NSString*) fingerprintStringTypeForFingerprintType:(OTRFingerprintType)fingerprintType {
    switch (fingerprintType) {
        case OTRFingerprintTypeAxolotl:
            return @"axolotl";
            break;
        case OTRFingerprintTypeGPG:
            return @"gpg";
            break;
        case OTRFingerprintTypeOTR:
            return @"otr";
            break;
        default:
            return nil;
            break;
    }
}

@end
