//
//  NSURL+chatsecure.h
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (ChatSecure)

+ (NSURL*) otr_githubURL;

+ (NSURL*) otr_facebookAppURL;
+ (NSURL*) otr_facebookWebURL;

+ (NSURL*) otr_twitterAppURL;
+ (NSURL*) otr_twitterWebURL;

+ (NSURL*) otr_transifexURL;
+ (NSURL*) otr_projectURL;

+ (NSURL*) otr_shareBaseURL;

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
           base64Encoded:(BOOL)base64Encoded;

/**
 *  Synchronously decodes a url into the given username and fingerprint.
 *  If this is not a share link it still may return something that is not a valid
 *  username or fingerprint. So you need to know ahead of calling this method
 *  if the url is a sharable url adhering to the spec.
 *
 *  @param completion a block that will be called with the decoded username and fingerprint
 */
- (void) otr_decodeShareLink:(void (^)(NSString *username, NSString *fingerprint))completion;

/** Checks if URL contains '/i/#' for the invite links of this style: https://chatsecure.org/i/#YWhkdmRqZW5kYmRicmVpQGR1a2dvLmNvbT9vdHI9M0EyN0FDODZBRkVGOENGMDlEOTAyMEQwNTJBNzNGMUVGMEQyOUI2Rg */
- (BOOL) otr_isInviteLink;

@end
