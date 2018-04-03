//
//  OTRSignalIdentity.m
//  ChatSecure
//
//  Created by David Chiles on 7/21/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRAccountSignalIdentity.h"

@implementation OTRAccountSignalIdentity

- (nullable instancetype)initWithAccountKey:(NSString *)accountKey identityKeyPair:(SignalIdentityKeyPair *)identityKeyPair registrationId:(uint32_t)registrationId
{
    if (self = [super initWithUniqueId:accountKey]) {
        self.accountKey = accountKey;
        self.identityKeyPair = identityKeyPair;
        self.registrationId = registrationId;
    }
    return self;
}

@end
