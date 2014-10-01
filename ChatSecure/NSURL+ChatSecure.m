//
//  NSURL+chatsecure.m
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "NSURL+ChatSecure.h"
#import "OTRConstants.h"

@implementation NSURL (ChatSecure)

- (BOOL)otr_isFacebookCallBackURL
{
    NSString *facebookScheme = [NSString stringWithFormat:@"fb%@",FACEBOOK_APP_ID];
    return [[self scheme] isEqualToString:facebookScheme];
}

+ (NSURL*) otr_githubURL {
    NSURL *githubURL = [NSURL URLWithString:@"https://github.com/chrisballinger/ChatSecure-iOS/"];
    return githubURL;
}

+ (NSURL*) otr_facebookAppURL {
    NSURL *facebookURL = [NSURL URLWithString:@"fb://profile/151354555075008"];
    return facebookURL;
}

+ (NSURL*) otr_facebookWebURL {
    NSURL *facebookURL = [NSURL URLWithString:@"https://www.facebook.com/chatsecure"];
    return facebookURL;
}

+ (NSURL*) otr_twitterAppURL {
    NSURL *twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=ChatSecure"];
    return twitterURL;
}
+ (NSURL*) otr_twitterWebURL {
    NSURL *twitterURL = [NSURL URLWithString:@"https://twitter.com/ChatSecure"];
    return twitterURL;
}

+ (NSURL*) otr_transifexURL {
    return [NSURL URLWithString:@"https://www.transifex.com/projects/p/chatsecure"];
}

+ (NSURL*) otr_projectURL {
    return [NSURL URLWithString:@"https://chatsecure.org"];
}
@end
