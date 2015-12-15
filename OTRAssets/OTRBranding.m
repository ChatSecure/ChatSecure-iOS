//
//  OTRBranding.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 9/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBranding.h"
#import "OTRAssets.h"

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





+ (NSDictionary*) defaultPlist {
    NSBundle *bundle = [OTRAssets resourcesBundle];
    NSString *path = [bundle pathForResource:@"Branding" ofType:@"plist"];
    NSParameterAssert(path != nil);
    NSDictionary *plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSParameterAssert(plist != nil);
    return plist;
}

@end
