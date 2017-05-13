//
//  NSURL+chatsecure.h
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import UIKit;
@import XMPPFramework;

NS_ASSUME_NONNULL_BEGIN
@interface NSURL (ChatSecure)

@property (nonatomic, class, readonly) NSURL *otr_githubURL;

@property (nonatomic, class, readonly) NSURL *otr_facebookAppURL;
@property (nonatomic, class, readonly) NSURL *otr_facebookWebURL;

@property (nonatomic, class, readonly) NSURL *otr_twitterAppURL;
@property (nonatomic, class, readonly) NSURL *otr_twitterWebURL;

@property (nonatomic, class, readonly) NSURL *otr_transifexURL;
@property (nonatomic, class, readonly) NSURL *otr_projectURL;

@property (nonatomic, class, readonly) NSURL *otr_shareBaseURL;

/**
 *  This method creates a shareable link based on the spec described
 here https://dev.guardianproject.info/projects/gibberbot/wiki/Invite_Links
 *  Of the style: https://chatsecure.org/i/#YWhkdmRqZW5kYmRicmVpQGR1a2dvLmNvbT9vdHI9M0EyN0FDODZBRkVGOENGMDlEOTAyMEQwNTJBNzNGMUVGMEQyOUI2Rg
 *
 *  @param baseURL the base url that the username and fingerprint will be added to
 *  @param username the username of your own account
 *  @param fingerprints the users fingerprints. key=OTRFingerprintType->NSString, value=fingerprintSTring
 *  @return a url that is shareable
 *
 *  @see +fingerprintStringTypeForFingerprintType:
 */
+ (nullable NSURL*) otr_shareLink:(NSURL *)baseURL
                              jid:(XMPPJID *)jid
                       queryItems:(nullable NSArray<NSURLQueryItem*> *)queryItems;

/**
 *  Synchronously decodes a url into the given username and fingerprint.
 *  If this is not a share link it still may return something that is not a valid
 *  username or fingerprint. So you need to know ahead of calling this method
 *  if the url is a sharable url adhering to the spec.
 *
 *  @param completion a block that will be called with the decoded username and fingerprint
 */
- (void) otr_decodeShareLink:(void (^)(XMPPJID * _Nullable jid, NSArray<NSURLQueryItem*> * _Nullable queryItems))completion;

/** Checks if share link indicates user has migrated.  m=1 */
+ (BOOL) otr_queryItemsContainMigrationHint:(NSArray<NSURLQueryItem*> *)queryItems;

/** Checks if URL contains '/i/#' for the invite links of this style: https://chatsecure.org/i/#YWhkdmRqZW5kYmRicmVpQGR1a2dvLmNvbT9vdHI9M0EyN0FDODZBRkVGOENGMDlEOTAyMEQwNTJBNzNGMUVGMEQyOUI2Rg */
@property (nonatomic, readonly) BOOL otr_isInviteLink;

/** This will give a user a prompt before calling openURL */
- (void) promptToShowURLFromViewController:(UIViewController*)viewController sender:(id)sender;

@end

@interface UIViewController (ChatSecureURL)
- (void) promptToShowURL:(NSURL*)url sender:(id)sender;
@end
NS_ASSUME_NONNULL_END
