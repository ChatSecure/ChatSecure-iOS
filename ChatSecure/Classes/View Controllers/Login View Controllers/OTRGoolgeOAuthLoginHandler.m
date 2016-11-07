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
#import "OTRXMPPLoginHandler.h"
#import "OTRXMPPManager.h"

@implementation OTRGoolgeOAuthLoginHandler

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTROAuthXMPPAccount *)account progress:(void (^)(NSInteger progress, NSString *summaryString))progress completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    [OTROAuthRefresher refreshAccount:account completion:^(id token, NSError *error) {
        if (!error) {
            account.accountSpecificToken = token;
            [super performActionWithValidForm:form account:account progress:progress completion:completion];
        } else if (completion) {
            //Error refreshing account
            completion(account, error);
        }
    }];
}

// Override superclass to prevent password clash
- (void) finishConnectingWithForm:(XLFormDescriptor *)form account:(OTRXMPPAccount *)account {
    [self prepareForXMPPConnectionFrom:form account:account];
    [self.xmppManager connectUserInitiated:YES];
}

@end
