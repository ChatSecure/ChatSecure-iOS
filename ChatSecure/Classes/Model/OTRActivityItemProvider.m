//
//  OTRActivityItemProvider.m
//  Off the Record
//
//  Created by David on 5/30/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRActivityItemProvider.h"
#import "OTRStrings.h"
#import "OTRQRCodeActivity.h"
#import "OTRLanguageManager.h"

static NSString *const kShareURL = @"https://get.chatsecure.org";

@implementation OTRActivityItemProvider


-(id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}
-(id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    NSString *shareString = [self shareString];
    
    if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        shareString = [NSString stringWithFormat:@"%@", [self twitterShareString]];
    } else if ([activityType isEqualToString:kOTRActivityTypeQRCode]) {
        shareString = kShareURL;
    }
    
    return shareString;
}

- (NSString*) shareString {
    return [NSString stringWithFormat:@"%@: %@", SHARE_MESSAGE_STRING, kShareURL];
}

- (NSString*) twitterShareString {
    return [NSString stringWithFormat:@"%@ @ChatSecure", [self shareString]];
}
@end
