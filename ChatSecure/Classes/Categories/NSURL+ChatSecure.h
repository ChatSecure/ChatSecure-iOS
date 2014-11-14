//
//  NSURL+chatsecure.h
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (ChatSecure)

- (BOOL)otr_isFacebookCallBackURL;

+ (NSURL*) otr_githubURL;

+ (NSURL*) otr_facebookAppURL;
+ (NSURL*) otr_facebookWebURL;

+ (NSURL*) otr_twitterAppURL;
+ (NSURL*) otr_twitterWebURL;

+ (NSURL*) otr_transifexURL;
+ (NSURL*) otr_projectURL;

@end
