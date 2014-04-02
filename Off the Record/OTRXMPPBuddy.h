//
//  OTRXMPPBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"

extern const struct OTRXMPPBuddyAttributes {
	__unsafe_unretained NSString *pendingApproval;
} OTRXMPPBuddyAttributes;

@interface OTRXMPPBuddy : OTRBuddy

@property (nonatomic, getter = isPendingApproval) BOOL pendingApproval;

@end
