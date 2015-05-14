//
//  OTRXMPPTorLoginHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPTorLoginHandler.h"

@implementation OTRXMPPTorLoginHandler

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account completion:(void (^)(NSError *, OTRAccount *))completion
{
    //check tor
    BOOL torIsRunning = NO;
    if (torIsRunning) {
        [super performActionWithValidForm:form account:account completion:completion];
    }
}

@end
