//
//  NSURL+chatsecure.m
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "NSURL+ChatSecure.h"
#import "OTRConstants.h"
#import "XMPPJID.h"
@import OTRAssets;

@implementation NSURL (ChatSecure)

+ (NSURL*) otr_githubURL {
    return [OTRBranding githubURL];
}

+ (NSURL*) otr_facebookAppURL {
    return [OTRBranding facebookAppURL];
}

+ (NSURL*) otr_facebookWebURL {
    return [OTRBranding facebookWebURL];
}

+ (NSURL*) otr_twitterAppURL {
    return [OTRBranding twitterAppURL];
}

+ (NSURL*) otr_twitterWebURL {
    return [OTRBranding twitterWebURL];
}

+ (NSURL*) otr_transifexURL {
    return [OTRBranding transifexURL];
}

+ (NSURL*) otr_projectURL {
    return [OTRBranding projectURL];
}

+ (NSURL*) otr_shareBaseURL {
    return [OTRBranding shareBaseURL];
}


//As described https://dev.guardianproject.info/projects/gibberbot/wiki/Invite_Links
+ (NSURL*) otr_shareLink:(NSString *)baseURL
                username:(NSString *)username
             fingerprint:(NSString *)fingerprint
           base64Encoded:(BOOL)base64Encoded
{
    NSParameterAssert(baseURL);
    NSParameterAssert(username);
    NSString *urlString = nil;
    if (base64Encoded) {
        NSString *user = username;
        if ([fingerprint length]) {
            user = [user stringByAppendingFormat:@"?otr=%@",fingerprint];
        }
        
        NSString *base64String = [[user dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
        
        if(base64String) {
            urlString = [NSString stringWithFormat:@"%@%@", baseURL, base64String];
        }
    } else {
        urlString = [baseURL stringByAppendingString:username];
        if ([fingerprint length]) {
            urlString = [urlString stringByAppendingString:fingerprint];
        }
    }
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

//As described https://dev.guardianproject.info/projects/gibberbot/wiki/Invite_Links
- (void)otr_decodeShareLink:(void (^)(NSString *, NSString *))completion
{
    if (!completion) {
        return;
    }
    
    NSString *lastComponent = self.lastPathComponent;
    XMPPJID *jid = [XMPPJID jidWithString:lastComponent];
    if ([[jid user] length]) {
        completion([jid bare],nil);
    } else {
        NSString *secondToLast = [self URLByDeletingLastPathComponent].lastPathComponent;
        jid = [XMPPJID jidWithString:secondToLast];
        if ([[jid user] length]) {
            completion([jid bare],lastComponent);
        } else {
            //Base64
            NSData *data = [[NSData alloc] initWithBase64EncodedString:lastComponent options:0];
            NSString *utf8String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSArray *components = [utf8String componentsSeparatedByString:@"?otr="];
            completion(components.firstObject, components.lastObject);
        }
    }
    
    
}
@end
