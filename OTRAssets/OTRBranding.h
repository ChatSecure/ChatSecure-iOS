//
//  OTRBranding.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 9/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString *const kOTRDefaultLanguageLocale;
FOUNDATION_EXPORT NSString *const kOTRSettingKeyLanguage;

/** Stub class for identifying asset framework bundle via bundleForClass: */
@interface OTRAssets : NSObject

/** Returns OTRResources.bundle */
+ (NSBundle*) resourcesBundle;

@end

@interface OTRBranding : NSObject

#pragma mark Strings

/** The default XMPP resource (e.g. username@example.com/chatsecure) */
+ (NSString*) xmppResource;

/** Email for user feedback e.g. support@chatsecure.org */
+ (NSString*) feedbackEmail;

/** Google Apps GOOGLE_APP_ID */
+ (NSString*) googleAppId;

/** Google Apps Scope e.g. https://www.googleapis.com/auth/googletalk */
+ (NSString*) googleAppScope;

#pragma mark URLs

/** Project source code on GitHub */
+ (NSURL*) githubURL;

/** Facebook App URL (launches FB app) */
+ (NSURL*) facebookAppURL;

/** Facebook Web URL */
+ (NSURL*) facebookWebURL;

/** Twitter App URL (launches Twitter app) */
+ (NSURL*) twitterAppURL;

/** Twitter Web URL */
+ (NSURL*) twitterWebURL;

/** Transifex URL */
+ (NSURL*) transifexURL;

/** Project URL e.g. https://chatsecure.org */
+ (NSURL*) projectURL;

/** Share Base URL e.g. https://chatsecure.org/i/# */
+ (NSURL*) shareBaseURL;

/** Push server URL e.g. https://push.example.com/api/v1/ */
+ (NSURL *)pushAPIURL;

/** Push staging server URL e.g. https://staging.push.example.com/api/v1/ */
+ (nullable NSURL *)pushStagingAPIURL;

/** UserVoice Site */
+ (nullable NSString*) userVoiceSite;

/** If enabled, will show a ⚠️ symbol next to your account when push may have issues */
+ (BOOL) shouldShowPushWarning;

/** If enabled, the server selection cell will be shown when creating new accounts. Otherwise it will be hidden in the 'advanced' section. */
+ (BOOL) shouldShowServerCell;

/** If enabled, will show colors for status indicators. */
@property (class, readonly) BOOL showsColorForStatus;

/** If enabled, will allow the in-app-purchase donations UI. This includes hardcoded elements designed for upstream ChatSecure. */
@property (class, readonly) BOOL allowsDonation;

@end
NS_ASSUME_NONNULL_END
