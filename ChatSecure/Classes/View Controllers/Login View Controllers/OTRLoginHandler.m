//
//  OTRLoginHandler.m
//  ChatSecure
//
//  Created by David Chiles on 6/17/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRLoginHandler.h"
#import "OTRXMPPLoginHandler.h"
#import "OTRGoolgeOAuthLoginHandler.h"
#import "OTRAccount.h"
#import "OTRXMPPAccount.h"
#import "OTRGoogleOAuthXMPPAccount.h"

@implementation OTRLoginHandler

+ (id<OTRBaseLoginViewControllerHandlerProtocol>)loginHandlerForAccount:(OTRAccount *)account
{
    id<OTRBaseLoginViewControllerHandlerProtocol>loginHandler = nil;
    if (account.accountType == OTRAccountTypeGoogleTalk) {
        loginHandler = [[OTRGoolgeOAuthLoginHandler alloc] init];
    } else if (account.accountType == OTRAccountTypeJabber || account.accountType == OTRAccountTypeXMPPTor) {
        loginHandler = [[OTRXMPPLoginHandler alloc] init];
    }
    NSParameterAssert(loginHandler != nil);
    return loginHandler;
}

@end
