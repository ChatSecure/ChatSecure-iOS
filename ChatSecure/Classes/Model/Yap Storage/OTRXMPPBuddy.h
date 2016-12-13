//
//  OTRXMPPBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"
#import "OTRvCard.h"

@class XMPPvCardTemp;

@interface OTRXMPPBuddy : OTRBuddy <OTRvCard>


/** This is for outgoing subscription requests */
@property (nonatomic, getter = isPendingApproval) BOOL pendingApproval;
/** Incoming subscription requests mean this object is a stub/placeholder */
@property (nonatomic) BOOL hasIncomingSubscriptionRequest;

- (void)setStatus:(OTRThreadStatus)status forResource:(NSString *)resource;
- (OTRThreadStatus)statusForResource:(NSString*)resource;



@end
