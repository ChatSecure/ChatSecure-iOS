//
//  OTRXMPPBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPBuddy.h"

const struct OTRXMPPBuddyAttributes OTRXMPPBuddyAttributes = {
	.pendingApproval = @"pendingApproval"
};


@implementation OTRXMPPBuddy

- (id)init
{
    if (self = [super init]) {
        self.pendingApproval = NO;
    }
    return self;
}


#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super initWithCoder:decoder]) {
        self.pendingApproval = [decoder decodeBoolForKey:OTRXMPPBuddyAttributes.pendingApproval];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeBool:self.isPendingApproval forKey:OTRXMPPBuddyAttributes.pendingApproval];
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OTRXMPPBuddy *copy = [super copyWithZone:zone];
    copy.pendingApproval = self.pendingApproval;
    
    return copy;
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRBuddy collection];
}



@end
