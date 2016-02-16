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


/**
 *  This method creates a shareable link based on the spec described
 here https://dev.guardianproject.info/projects/gibberbot/wiki/Invite_Links
 *  Of the style: https://chatsecure.org/i/#YWhkdmRqZW5kYmRicmVpQGR1a2dvLmNvbT9vdHI9M0EyN0FDODZBRkVGOENGMDlEOTAyMEQwNTJBNzNGMUVGMEQyOUI2Rg
 *
 *  @param baseURL the base url that the username and fingerprint will be added to
 *  @param username the username of your own account
 *  @param fingerprints the users fingerprints. key=OTRFingerprintType->NSString, value=fingerprintSTring
 *  @param base64Encoded whether to base64 encode the last path component
 *  @return a url that is shareable
 *
 *  @see +fingerprintStringTypeForFingerprintType:
 */
+ (NSURL*) otr_shareLink:(NSString *)baseURL
                username:(NSString *)username
            fingerprints:(NSDictionary <NSString*, NSString*> *)fingerprints
           base64Encoded:(BOOL)base64Encoded {
    NSParameterAssert(baseURL);
    NSParameterAssert(username);
    NSString *urlString = @"";
    
    NSMutableString *fingerprintsString = [NSMutableString string];
    
    if (fingerprints.count > 0) {
        [fingerprints enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [fingerprintsString appendFormat:@"?%@=%@",key,obj];
        }];
    }
    
    // The part after the /i/#
    NSString *anchor = [NSString stringWithFormat:@"%@%@", username, fingerprintsString];
    
    if (base64Encoded) {
        anchor = [[anchor dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
        NSParameterAssert(anchor != nil);
        if (!anchor.length) {
            return nil;
        }
        //Use url safe flavor of base64
        anchor = [anchor stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
        anchor = [anchor stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    }
    urlString = [NSString stringWithFormat:@"%@%@", baseURL, anchor];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

//As described https://dev.guardianproject.info/projects/gibberbot/wiki/Invite_Links
- (void)otr_decodeShareLink:(void (^)(NSString *username, NSString *fingerprint))completion
{
    if (!completion) {
        return;
    }
    
    if (![self otr_isInviteLink]) {
        completion(nil, nil);
        return;
    }
    
    NSString *urlString = self.absoluteString;
    
    NSArray *components = [urlString componentsSeparatedByString:@"/i/#"];
    
    if (components.count != 2) {
        completion(nil, nil);
        return;
    }
    
    NSString *base64String = components[1];
    
    base64String = [base64String stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    base64String = [base64String stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    
    // Apple's base64 decoder requires padding http://stackoverflow.com/a/21407393/805882
    if (base64String.length % 4 != 0) {
        int remainder = base64String.length % 4;
        NSMutableString *padding = [[NSMutableString alloc] init];
        for (int i = 0; i < (4 - remainder); i++) {
            [padding appendString:@"="];
        }
        base64String = [base64String stringByAppendingString:padding];
    }
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    if (!data) {
        completion(nil, nil);
        return;
    }
    
    NSString *utf8String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    components = [utf8String componentsSeparatedByString:@"?otr="];
    if (components.count == 0) {
        completion(utf8String, nil);
    } else if (components.count == 2) {
        completion(components.firstObject, components.lastObject);
    } else {
        completion(nil, nil);
    }
}


/** Checks if URL contains '/i/#' for the invite links of this style: https://chatsecure.org/i/#YWhkdmRqZ... */
- (BOOL) otr_isInviteLink {
    return [self.absoluteString containsString:@"/i/#"];
}

@end
