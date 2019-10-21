//
//  OTREncryptionManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

@import Foundation;
@class OTRKit, OTRDataHandler, OTRFingerprint;

extern NSString * _Nonnull const OTRMessageStateDidChangeNotification;
extern NSString * _Nonnull const OTRWillStartGeneratingPrivateKeyNotification;
extern NSString * _Nonnull const OTRDidFinishGeneratingPrivateKeyNotification;
extern NSString * _Nonnull const OTRMessageStateKey;

// This is a hack to get around problems using OTRKit.h in swift files
typedef NS_ENUM(NSUInteger, OTREncryptionMessageState) {
    OTREncryptionMessageStatePlaintext,
    OTREncryptionMessageStateEncrypted,
    OTREncryptionMessageStateFinished,
    OTREncryptionMessageStateError
};
NS_ASSUME_NONNULL_BEGIN

@interface OTREncryptionManager:NSObject

@property (nonatomic, strong, readonly) OTRKit *otrKit;
@property (nonatomic, strong, readonly) OTRDataHandler *dataHandler;

/**
 * This method takes a buddy key and collection. If it finds an object in the database and `hasGoneEncryptedBefore` is true
 * It will try to initiate a new OTR session. This is useful when re-entering a converstaion with a buddy.
 * This will bail out unless buddy.preferredSecurity == .OTR
 *
 * @param buddyKey The Yap key for the buddy
 * @param collection The Yap collection for the buddy
 */
- (void)maybeRefreshOTRSessionForBuddyKey:(NSString *)buddyKey collection:(NSString *)collection;

/** 
 * This is the only way the trust for an OTR fingerprint should be checked. This goes through an internal cache to speed up checks.
 *
 * @param key the buddy yap key
 * @param collection The buddy collection
 * @param fingerprint The Data for the fingerprint. Since one buddy may have multiple fingerprints of different trust levels.
 *
 * @returns An OTRFingerPrint object either from the internal cache or OTRKit.
 */
- (nullable OTRFingerprint *)otrFingerprintForKey:(NSString *)key collection:(NSString *)collection fingerprint:(NSData *)fingerprint;

/**
 * Save a fingerprint to file with OTRKit. Use this to save instead of accessing OTRKit directly so it goes through an internal cache.
 * 
 * @param fingerprint The fingerprint to be saved.
 */
- (void)saveFingerprint:(OTRFingerprint *)fingerprint;

/**
 * Remove a fingerprint from the OTRKit store. use this to remove a fingerprint so it goes through an internal cache.
 *
 * @param fingerprint The fingerprint object to be removed.
 * @param error Any errors from OTRKit
 *
 * @return If the the removal was successful
 */
- (BOOL)removeOTRFingerprint:(OTRFingerprint *)fingerprint error:( NSError * _Nullable *)error;

+ (BOOL) setFileProtection:(NSString*)fileProtection path:(NSString*)path;
+ (BOOL) addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

+ (OTREncryptionMessageState)convertEncryptionState:(NSUInteger)messageState;



@end

NS_ASSUME_NONNULL_END
