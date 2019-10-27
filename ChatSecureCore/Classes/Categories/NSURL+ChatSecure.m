//
//  NSURL+chatsecure.m
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "NSURL+ChatSecure.h"
#import "OTRConstants.h"
@import XMPPFramework;
@import OTRAssets;
#import "ChatSecureCoreCompat-Swift.h"

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
+ (NSURL*) otr_shareLink:(NSURL *)baseURL
                     jid:(XMPPJID *)jid
              queryItems:(nullable NSArray<NSURLQueryItem*> *)queryItems {
    NSParameterAssert(baseURL);
    NSParameterAssert(jid);
    BOOL base64Encoded = YES;
    NSString *username = jid.bare;
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:baseURL resolvingAgainstBaseURL:YES];
    //urlComponents.path = [NSString stringWithFormat:@"/%@", username];
    urlComponents.queryItems = queryItems;
    NSString *query = urlComponents.query;
    urlComponents.queryItems = nil;
    
    // The part after the /i/#
    NSString *anchor = [NSString stringWithFormat:@"%@?%@", username, query];
    
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
    urlComponents.fragment = anchor;
    return urlComponents.URL;
}

//As described https://dev.guardianproject.info/projects/gibberbot/wiki/Invite_Links
- (void) otr_decodeShareLink:(void (^)(XMPPJID * _Nullable jid, NSArray<NSURLQueryItem*> * _Nullable queryItems))completion
{
    NSParameterAssert(completion);
    if (!completion) {
        return;
    }
    
    if (![self otr_isInviteLink]) {
        completion(nil, nil);
        return;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    if (!components) {
        completion(nil, nil);
        return;
    }
    
    NSString *base64String = components.fragment;
    if (!base64String) {
        completion(nil, nil);
        return;
    }
    
    // Using URL-encoded base64
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
    if (!utf8String) {
        completion(nil, nil);
        return;
    }
    // Generate a fake URL so we can use NSURLComponents
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    urlComponents.fragment = nil;
    urlComponents.path = nil;
    NSURL *baseURL = urlComponents.URL;
    NSString *fakeUrlString = [NSString stringWithFormat:@"%@/%@", baseURL.absoluteString, [utf8String stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
    
    NSURL *fakeURL = [NSURL URLWithString:fakeUrlString];
    if (!fakeURL) {
        completion(nil, nil);
        return;
    }
    urlComponents = [NSURLComponents componentsWithURL:fakeURL resolvingAgainstBaseURL:NO];
    if (!urlComponents) {
        completion(nil, nil);
        return;
    }
    if (urlComponents.path.length <= 1) {
        completion(nil, nil);
        return;
    }
    NSString *username = [urlComponents.path substringFromIndex:1]; // Remove '/' character
    NSArray<NSURLQueryItem*> *queryItems = urlComponents.queryItems;
    
    XMPPJID *jid = [XMPPJID jidWithString:username];
    
    completion(jid, queryItems);
}

/** Checks for m=1 */
+ (BOOL) otr_queryItemsContainMigrationHint:(NSArray<NSURLQueryItem*> *)queryItems {
    NSParameterAssert(queryItems);
    if (!queryItems) {
        return NO;
    }
    __block BOOL migrationHint = NO;
    [queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:@"m"] && [obj.value isEqualToString:@"1"]) {
            migrationHint = YES;
            *stop = YES;
        }
    }];
    return migrationHint;
}


/** Checks if URL contains '/i/#' for the invite links of this style: https://chatsecure.org/i/#YWhkdmRqZ... */
- (BOOL) otr_isInviteLink {
    return [self.absoluteString containsString:@"/i/#"];
}

/** This will give a user a prompt before calling openURL */
- (void) promptToShowURLFromViewController:(UIViewController*)viewController sender:(id)sender {
    if (!viewController) { return; }
    UIView *view = nil;
    if ([sender isKindOfClass:[UIView class]]) {
        view = sender;
    }
    UIAlertAction *visitURL = [UIAlertAction actionWithTitle:OPEN_IN_SAFARI() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[UIApplication sharedApplication] open:self];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:CANCEL_STRING() style:UIAlertActionStyleCancel handler:nil];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.absoluteString message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:visitURL];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.sourceView = view;
    alert.popoverPresentationController.sourceRect = view.bounds;
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end

@implementation UIViewController (ChatSecureURL)
- (void) promptToShowURL:(NSURL*)url sender:(id)sender {
    [url promptToShowURLFromViewController:self sender:sender];
}


@end
