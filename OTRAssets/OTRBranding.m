//
//  OTRBranding.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 9/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBranding.h"

NSString *const kOTRSettingKeyLanguage                 = @"userSelectedSetting";
NSString *const kOTRDefaultLanguageLocale = @"kOTRDefaultLanguageLocale";

static NSString *const kOTRXMPPResource = @"kOTRXMPPResource";
static NSString *const kOTRFeedbackEmail = @"kOTRFeedbackEmail";
static NSString *const GOOGLE_APP_ID    = @"GOOGLE_APP_ID";
static NSString *const GOOGLE_APP_SCOPE = @"GOOGLE_APP_SCOPE";

@implementation OTRBranding

#pragma mark URLs

/** Project source code on GitHub */
+ (NSURL*) githubURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"GitHubURL"];
    NSURL *githubURL = [NSURL URLWithString:urlString];
    return githubURL;
}

/** Facebook App URL */
+ (NSURL*) facebookAppURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"FacebookAppURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}


/** Facebook Web URL */
+ (NSURL*) facebookWebURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"FacebookWebURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

/** Twitter App URL */
+ (NSURL*) twitterAppURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"TwitterAppURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

/** Twitter Web URL */
+ (NSURL*) twitterWebURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"TwitterWebURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

/** Transifex URL */
+ (NSURL*) transifexURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"TransifexURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

/** Project URL */
+ (NSURL*) projectURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"ProjectURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

/** Share Base URL */
+ (NSURL*) shareBaseURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"ShareBaseURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

/** Push server URL e.g. https://chatsecure-push.herokuapp.com/api/v1/ */
+ (NSURL *)pushAPIURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"pushAPIURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

/** Push staging server URL e.g. https://chatsecure-push.herokuapp.com/api/v1/ */
+ (NSURL *)pushStagingAPIURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"StagingPushAPIURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

+ (NSURL *)testflightSignupURL {
    NSString *urlString = [[self defaultPlist] objectForKey:@"TestflightSignupURL"];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

#pragma mark Strings

/** The default XMPP resource (e.g. username@example.com/chatsecure) */
+ (NSString*) xmppResource {
    return [[self defaultPlist] objectForKey:kOTRXMPPResource];
}

/** Email for user feedback e.g. support@chatsecure.org */
+ (NSString*) feedbackEmail {
    return [[self defaultPlist] objectForKey:kOTRFeedbackEmail];
}

/** Google Apps GOOGLE_APP_ID */
+ (NSString*) googleAppId {
    return [[self defaultPlist] objectForKey:GOOGLE_APP_ID];
}

/** Google Apps Scope e.g. https://www.googleapis.com/auth/googletalk */
+ (NSString*) googleAppScope {
    return [[self defaultPlist] objectForKey:GOOGLE_APP_SCOPE];
}

/** UserVoice Site */
+ (nullable NSString*) userVoiceSite {
    return [[self defaultPlist] objectForKey:@"UserVoiceSite"];
}

/** UserVoice Site */
+ (nullable NSString*) appStoreID {
    return [[self defaultPlist] objectForKey:@"AppStoreID"];
}

/** If enabled, will show a ⚠️ symbol next to your account when push may have issues */
+ (BOOL) shouldShowPushWarning {
    BOOL result = [[[self defaultPlist] objectForKey:@"ShouldShowPushWarning"] boolValue];
    return result;
}

/** If enabled, the server selection cell will be shown when creating new accounts. Otherwise it will be hidden in the 'advanced' section. */
+ (BOOL) shouldShowServerCell {
    BOOL result = [[[self defaultPlist] objectForKey:@"ShouldShowServerCell"] boolValue];
    return result;
}

+ (BOOL) showsColorForStatus {
    BOOL result = [[[self defaultPlist] objectForKey:@"ShowsColorForStatus"] boolValue];
    return result;
}

+ (BOOL) torEnabled {
    BOOL result = [[[self defaultPlist] objectForKey:@"TorEnabled"] boolValue];
    return result;
}

+ (BOOL) allowGroupOMEMO {
    if (![self allowOMEMO]) {
        return NO;
    }
    BOOL result = [[[self defaultPlist] objectForKey:@"AllowGroupOMEMO"] boolValue];
    return result;
}

+ (BOOL) allowDebugFileLogging {
    BOOL result = [[[self defaultPlist] objectForKey:@"AllowDebugFileLogging"] boolValue];
    return result;
}

+ (BOOL) allowOMEMO {
    NSNumber *result = [[self defaultPlist] objectForKey:@"AllowOMEMO"];
    if (!result) {
        return YES;
    } else {
        return result.boolValue;
    }
}

/** Returns true if we're running the official ChatSecure */
+ (BOOL) matchesUpstream {
    return [[[NSBundle mainBundle] bundleIdentifier] containsString:@"com.chrisballinger.ChatSecure"];
}

+ (BOOL) allowsDonation {
    // Only allow this for upstream
    if (![self matchesUpstream]) {
        return NO;
    }
    BOOL result = [[[self defaultPlist] objectForKey:@"AllowsDonation"] boolValue];
    return result;
}

+ (NSDictionary*) defaultPlist {
    // Normally this won't be nil, but they WILL be nil during tests.
    NSBundle *bundle = [OTRAssets resourcesBundle];
    NSString *path = [bundle pathForResource:@"Branding" ofType:@"plist"];
    //NSParameterAssert(path != nil);
    NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    //NSParameterAssert(plist != nil);
    return plist;
}

@end

@implementation OTRAssets

/** Returns resources bundle */
+ (NSBundle*) resourcesBundle {
    return NSBundle.mainBundle;
}

@end
