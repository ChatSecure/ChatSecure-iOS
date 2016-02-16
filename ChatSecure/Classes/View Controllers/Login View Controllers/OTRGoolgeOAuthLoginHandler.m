//
//  OTRGoolgeOAuthLoginHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRGoolgeOAuthLoginHandler.h"
#import "OTRGoogleOAuthXMPPAccount.h"
#import "OTROAuthRefresher.h"

@implementation OTRGoolgeOAuthLoginHandler

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTROAuthXMPPAccount *)account completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    account = (OTROAuthXMPPAccount *)[self moveValues:form intoAccount:account];
    [OTROAuthRefresher refreshAccount:account completion:^(id token, NSError *error) {
        if (!error) {
            account.accountSpecificToken = token;
            [super performActionWithValidForm:form account:account completion:completion];
        } else if (completion) {
            //Error refreshing account
            completion(account, error);
        }
    }];
}

@end
