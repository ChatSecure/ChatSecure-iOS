//
//  OTRXMPPBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPGroup.h"
#import "XMPPvCardTemp.h"
#import "NSData+XMPP.h"

const struct OTRXMPPGroupAttributes OTRXMPPGroupAttributes = {
	.pendingApproval = @"pendingApproval",
    .vCardTemp = @"vCardTemp",
    .photoHash = @"photoHash",
    .waitingForvCardTempFetch = @"waitingForvCardTempFetch",
    .lastUpdatedvCardTemp = @"lastUpdatedvCardTemp"
};


@implementation OTRXMPPGroup

- (id)init
{
    if (self = [super init]) {
        
    }
    return self;
}

#pragma - mark setters & getters



#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRGroup collection];
}



@end
