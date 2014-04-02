//
//  OTRXMPPTorAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPTorAccount.h"

#import "OTRXMPPTorManager.h"
#import "Strings.h"


@implementation OTRXMPPTorAccount

- (UIImage *)accountImage
{
    return [UIImage imageNamed:OTRXMPPTorImageName];
}

- (NSString *)accountDisplayName
{
    return XMPP_TOR_STRING;
}

- (Class)protocolClass{
    return [OTRXMPPTorManager class];
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

@end
