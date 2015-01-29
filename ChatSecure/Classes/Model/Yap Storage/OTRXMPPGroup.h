//
//  OTRXMPPBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRGroup.h"

@class XMPPvCardTemp;

extern const struct OTRXMPPGroupAttributes {
	__unsafe_unretained NSString *pendingApproval;
	__unsafe_unretained NSString *vCardTemp;
	__unsafe_unretained NSString *photoHash;
    __unsafe_unretained NSString *waitingForvCardTempFetch;
    __unsafe_unretained NSString *lastUpdatedvCardTemp;
} OTRXMPPGroupAttributes;

@interface OTRXMPPGroup : OTRGroup

@property (nonatomic, strong) XMPPvCardTemp *vCardTemp;
@property (nonatomic, strong) NSDate *lastUpdatedvCardTemp;
@property (nonatomic, getter =  isWaitingForvCardTempFetch) BOOL waitingForvCardTempFetch;
@property (nonatomic, strong) NSString *photoHash;
@property (nonatomic, getter = isPendingApproval) BOOL pendingApproval;

@end
