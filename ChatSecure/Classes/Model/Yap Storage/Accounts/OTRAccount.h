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
#import "OTRUserInfoProfile.h"

typedef NS_ENUM(int, OTRAccountType) {
    OTRAccountTypeNone        = 0,
    OTRAccountTypeFacebook    = 1, // deprecated
    OTRAccountTypeGoogleTalk  = 2,
    OTRAccountTypeJabber      = 3,
    OTRAccountTypeAIM         = 4, // deprecated
    OTRAccountTypeXMPPTor     = 5
};

typedef NS_ENUM(int, OTRFingerprintType) {
    OTRFingerprintTypeNone        = 0,
    OTRFingerprintTypeOTR    = 1,
    OTRFingerprintTypeAxolotl  = 2,
    OTRFingerprintTypeGPG = 3
};

NS_ASSUME_NONNULL_BEGIN
extern NSString *const OTRAimImageName;
extern NSString *const OTRGoogleTalkImageName;
extern NSString *const OTRXMPPImageName;
extern NSString *const OTRXMPPTorImageName;

@interface OTRAccount : OTRYapDatabaseObject <OTRUserInfoProfile>

@property (nonatomic, strong) NSString *username;
@property (nonatomic, readonly) OTRAccountType accountType;

@property (nonatomic, strong) NSString *displayName;
/** Setting rememberPassword to false will remove keychain passwords */
@property (nonatomic) BOOL rememberPassword;
@property (nonatomic) BOOL autologin;

@property (nonatomic, readonly) BOOL isArchived;
/** Whether or not user would like to auto fetch media messages */
@property (nonatomic, readwrite) BOOL disableAutomaticURLFetching;

/**
 * Setting this value does a comparison of against the previously value
 * to invalidate the OTRImages cache.
 */
@property (nonatomic, strong, nullable) NSData *avatarData;

/** 
 * To remove the keychain password, you must explicitly call removeKeychainPassword
 * instead of setting empty string or nil 
 */
@property (nonatomic, strong, nullable) NSString *password;
/** Removes the account password from keychain */
- (BOOL) removeKeychainPassword:(NSError**)error;

/** Will return nil if accountType does not match class type. @see accountClassForAccountType: */
- (nullable instancetype)initWithUsername:(NSString*)username
                              accountType:(OTRAccountType)accountType NS_DESIGNATED_INITIALIZER;

/** Will return a concrete subclass of OTRAccount. @see accountClassForAccountType: */
+ (nullable __kindof OTRAccount*)accountWithUsername:(NSString*)username
                                         accountType:(OTRAccountType)accountType;

/** Not available, use designated initializer */
- (instancetype) init NS_UNAVAILABLE;

/**
 The current or generated avatar image either from avatarData or the initials from displayName or username
 
 @return An UIImage from the OTRImages NSCache
 */
- (UIImage *)avatarImage;

/** Image for XMPP logo, etc */
- (nullable UIImage *)accountImage;

/** Returns concrete subclass of OTRAccount corresponding to OTRAccountType */
+ (nullable Class) accountClassForAccountType:(OTRAccountType)accountType;
- (OTRProtocolType)protocolType;
/** Must implement in subclass to return class implementing id<OTRProtocol> */
- (Class)protocolClass;
- (NSString *)protocolTypeString;

- (NSArray <__kindof OTRBuddy *>*)allBuddiesWithTransaction:(YapDatabaseReadTransaction *)transaction;

+ (NSArray <OTRAccount *>*)allAccountsWithUsername:(NSString *)username transaction:(YapDatabaseReadTransaction*)transaction;
+ (NSArray <OTRAccount *>*)allAccountsWithTransaction:(YapDatabaseReadTransaction*)transaction;
+ (NSUInteger) numberOfAccountsWithTransaction:(YapDatabaseReadTransaction*)transaction;
+ (nullable OTRAccount*) accountForThread:(id<OTRThreadOwner>)thread transaction:(YapDatabaseReadTransaction*)transaction;

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
                                completion:(void (^)(NSURL* _Nullable shareURL, NSError* _Nullable error))completionBlock;

/**
 *  Returns string representation of OTRFingerprintType
 *
 *  - "otr" for OTRFingerprintTypeOTR
 *  - "omemo" for OTRFingerprintTypeAxolotl
 *  - "gpg" for OTRFingerprintTypeGPG
 *
 *  @return String representation of OTRFingerprintType
 */
+ (nullable NSString*) fingerprintStringTypeForFingerprintType:(OTRFingerprintType)fingerprintType;

@end
NS_ASSUME_NONNULL_END
