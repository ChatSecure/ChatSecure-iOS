//
//  OTROAuthRefresher.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTROAuthRefresher.h"

#import "GTMOAuth2Authentication.h"
#import "OTRSecrets.h"
#import "OTRConstants.h"

#import "OTROAuthXMPPAccount.h"


@implementation OTROAuthRefresher

+ (void)refreshGoogleToken:(GTMOAuth2Authentication *)authToken completion:(OTROAuthCompletionBlock)completionBlock
{
    [authToken authorizeRequest:nil completionHandler:^(NSError *error) {
        if (completionBlock) {
            if (!error) {
                completionBlock(authToken,nil);
            }
            else {
                completionBlock(nil,error);
            }
        }
    }];
}

+ (void)refreshAccount:(OTROAuthXMPPAccount *)account completion:(OTROAuthCompletionBlock)completionBlock
{
    if (account.accountType == OTRAccountTypeGoogleTalk) {
        [self refreshGoogleToken:[account accountSpecificToken] completion:completionBlock];
    }
}

@end
