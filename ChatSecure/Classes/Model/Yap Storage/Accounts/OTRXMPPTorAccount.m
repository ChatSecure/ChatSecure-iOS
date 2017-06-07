//
//  OTRXMPPTorAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPTorAccount.h"

#import "OTRXMPPTorManager.h"

@import OTRAssets;


@implementation OTRXMPPTorAccount

- (UIImage *)accountImage
{
    return [UIImage imageNamed:OTRXMPPTorImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
}

- (Class)protocolClass{
    return [OTRXMPPTorManager class];
}

- (BOOL) disableAutomaticURLFetching {
    return YES;
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

@end
