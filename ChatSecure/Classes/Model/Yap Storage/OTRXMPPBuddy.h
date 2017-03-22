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

extern NSString * _Nonnull const OTRBuddyPendingApprovalDidChangeNotification;

@interface OTRXMPPBuddy : OTRBuddy <OTRvCard>


/** This is for outgoing subscription requests */
@property (nonatomic) BOOL pendingApproval;
/** Incoming subscription requests mean this object is a stub/placeholder */
@property (nonatomic) BOOL hasIncomingSubscriptionRequest;




@end
