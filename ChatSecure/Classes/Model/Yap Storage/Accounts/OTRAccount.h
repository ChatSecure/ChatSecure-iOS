//
//  OTRAccount.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//
@import UIKit;
#import "OTRYapDatabaseObject.h"
#import "OTRProtocol.h"

typedef NS_ENUM(int, OTRAccountType) {
    OTRAccountTypeNone        = 0,
    OTRAccountTypeFacebook    = 1,
    OTRAccountTypeGoogleTalk  = 2,
    OTRAccountTypeJabber      = 3,
    OTRAccountTypeAIM         = 4,
    OTRAccountTypeXMPPTor     = 5
};

typedef NS_ENUM(int, OTRFingerprintType) {
    OTRFingerprintTypeNone        = 0,
    OTRFingerprintTypeOTR    = 1,
    OTRFingerprintTypeAxolotl  = 2,
    OTRFingerprintTypeGPG = 3
};

extern NSString *const OTRAimImageName;
extern NSString *const OTRGoogleTalkImageName;
extern NSString *const OTRXMPPImageName;
extern NSString *const OTRXMPPTorImageName;

@interface OTRAccount : OTRYapDatabaseObject

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, readonly) OTRAccountType accountType;
@property (nonatomic, strong) NSString *username;
/** Setting rememberPassword to false will remove keychain passwords */
@property (nonatomic) BOOL rememberPassword;
@property (nonatomic) BOOL autologin;

/**
 * Setting this value does a comparison of against the previously value
 * to invalidate the OTRImages cache.
 */
@property (nonatomic, strong) NSData *avatarData;

/** 
 * To remove the keychain password, you must explicitly call removeKeychainPassword
 * instead of setting empty string or nil 
 */
@property (nonatomic, strong) NSString *password;
/** Removes the account password from keychain */
- (BOOL) removeKeychainPassword:(NSError**)error;


- (id)initWithAccountType:(OTRAccountType)accountType;

/**
 The current or generated avatar image either from avatarData or the initials from displayName or username
 
 @return An UIImage from the OTRImages NSCache
 */
- (UIImage *)avatarImage;
- (Class)protocolClass;
- (UIImage *)accountImage;
- (OTRProtocolType)protocolType;
- (NSString *)accountDisplayName;
- (NSString *)protocolTypeString;

- (NSArray *)allBuddiesWithTransaction:(YapDatabaseReadTransaction *)transaction;

+ (OTRAccount *)accountForAccountType:(OTRAccountType)accountType;
+ (NSArray *)allAccountsWithUsername:(NSString *)username transaction:(YapDatabaseReadTransaction*)transaction;
+ (NSArray <OTRAccount *>*)allAccountsWithTransaction:(YapDatabaseReadTransaction*)transaction;

/**
 Remove all accounts with account type using a read/write transaction
 
 @param accountType the account type to remove
 @param transaction a readwrite yap transaction
 @return the number of accounts removed
 */
+ (NSUInteger)removeAllAccountsOfType:(OTRAccountType)accountType inTransaction:(YapDatabaseReadWriteTransaction *)transaction;

#pragma mark Fingerprints

/** 
 *  Returns the full share URL invite link for this account. Optionally includes fingerprints of various key types.
 *  
 *  @param fingerprintTypes (optional) include a NSSet of boxed of OTRFingerprintType values
 *  @param completion called on main queue with shareURL, or potentially nil if there's an error during link generation.
 */
- (void) generateShareURLWithFingerprintTypes:(NSSet <NSNumber*> *)fingerprintTypes
                                completion:(void (^)(NSURL* shareURL, NSError *error))completionBlock;

/**
 *  Returns string representation of OTRFingerprintType
 *
 *  - "otr" for OTRFingerprintTypeOTR
 *  - "omemo" for OTRFingerprintTypeAxolotl
 *  - "gpg" for OTRFingerprintTypeGPG
 *
 *  @return String representation of OTRFingerprintType
 */
+ (NSString*) fingerprintStringTypeForFingerprintType:(OTRFingerprintType)fingerprintType;

@end
