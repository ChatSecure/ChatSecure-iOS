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

/** Returns resources bundle */
@property (class, readonly) NSBundle* resourcesBundle;

@end

@interface OTRBranding : NSObject

#pragma mark Strings

/** The default XMPP resource (e.g. username@example.com/chatsecure) */
@property (class, readonly) NSString* xmppResource;

/** Email for user feedback e.g. support@chatsecure.org */
@property (class, readonly) NSString* feedbackEmail;

/** Google Apps GOOGLE_APP_ID */
@property (class, readonly) NSString* googleAppId;

/** Google Apps Scope e.g. https://www.googleapis.com/auth/googletalk */
@property (class, readonly) NSString* googleAppScope;

/** e.g. https://itunes.apple.com/app/idXXXXXXXXXX */
@property (class, readonly, nullable) NSString* appStoreID;

#pragma mark URLs

/** TestFlight signup URL */
@property (class, readonly) NSURL* testflightSignupURL;

/** Project source code on GitHub */
@property (class, readonly) NSURL* githubURL;

/** Facebook App URL (launches FB app) */
@property (class, readonly) NSURL* facebookAppURL;

/** Facebook Web URL */
@property (class, readonly) NSURL* facebookWebURL;

/** Twitter App URL (launches Twitter app) */
@property (class, readonly) NSURL* twitterAppURL;

/** Twitter Web URL */
@property (class, readonly) NSURL* twitterWebURL;

/** Transifex URL */
@property (class, readonly) NSURL* transifexURL;

/** Project URL e.g. https://chatsecure.org */
@property (class, readonly) NSURL* projectURL;

/** Share Base URL e.g. https://chatsecure.org/i/# */
@property (class, readonly) NSURL* shareBaseURL;

/** Push server URL e.g. https://push.example.com/api/v1/ */
@property (class, readonly) NSURL* pushAPIURL;

/** Push staging server URL e.g. https://staging.push.example.com/api/v1/ */
@property (class, readonly, nullable) NSURL* pushStagingAPIURL;

/** UserVoice Site */
@property (class, readonly, nullable) NSString* userVoiceSite DEPRECATED_MSG_ATTRIBUTE("UserVoice is deprecated.");

/** If enabled, will show a ⚠️ symbol next to your account when push may have issues */
@property (class, readonly) BOOL shouldShowPushWarning;

/** If enabled, the server selection cell will be shown when creating new accounts. Otherwise it will be hidden in the 'advanced' section. */
@property (class, readonly) BOOL shouldShowServerCell;

/** If enabled, will show colors for status indicators. */
@property (class, readonly) BOOL showsColorForStatus;

/** If enabled, will allow the in-app-purchase donations UI. This includes hardcoded elements designed for upstream ChatSecure. */
@property (class, readonly) BOOL allowsDonation;

/** If enabled, will show the Tor UI during account creation. Does not affect accounts already created. */
@property (class, readonly) BOOL torEnabled;

/** If enabled, will show UI for enabling OMEMO group encryption. Superceded by allowOMEMO setting. */
@property (class, readonly) BOOL allowGroupOMEMO;

/** If enabled, will show UI for managing debug log files. */
@property (class, readonly) BOOL allowDebugFileLogging;

/** If enabled, will allow OMEMO functionality within the app. Defaults to YES if setting key is not present. */
@property (class, readonly) BOOL allowOMEMO;

@end
NS_ASSUME_NONNULL_END
