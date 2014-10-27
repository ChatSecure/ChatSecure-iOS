//
//  UIActivityViewController+ChatSecure.m
//  ChatSecure
//
//  Created by David Chiles on 10/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "UIActivityViewController+ChatSecure.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"
#import "OTROpenInFacebookActivity.h"
#import "OTROpenInTwitterActivity.h"
#import "Strings.h"

@implementation UIActivityViewController (ChatSecure)

+ (instancetype)otr_linkActivityViewControllerWithURLs:(NSArray *)urlArray
{
    if ([urlArray count]) {
        TUSafariActivity *safariActivity = [TUSafariActivity new];
        ARChromeActivity *chromeActivity = [ARChromeActivity new];
        chromeActivity.activityTitle = OPEN_IN_CHROME;
        chromeActivity.callbackURL = [NSURL URLWithString:@"chatsecure://"];
        OTROpenInTwitterActivity *twitterActivity = [OTROpenInTwitterActivity new];
        OTROpenInFacebookActivity *facebookActivity = [OTROpenInFacebookActivity new];
        
        
        NSArray *applicationActivites  = @[twitterActivity,facebookActivity,safariActivity,chromeActivity];
        return [[self alloc] initWithActivityItems:urlArray applicationActivities:applicationActivites];
    }
    return nil;
}

@end
