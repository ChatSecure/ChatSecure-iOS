//
//  OTRXMPPBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"
#import "OTRvCard.h"

@import XMPPFramework;

/** Contains userInfo with buddy object in "buddy" key */
extern NSString * _Nonnull const OTRBuddyPendingApprovalDidChangeNotification;

@interface OTRXMPPBuddy : OTRBuddy <OTRvCard>

/** Returns the bare JID derived from the self.username property */
@property (nonatomic, strong, readonly, nullable) XMPPJID *bareJID;

/** This is for outgoing subscription requests */
@property (nonatomic) BOOL pendingApproval;
/** Incoming subscription requests mean this object is a stub/placeholder */
@property (nonatomic) BOOL hasIncomingSubscriptionRequest;

@end
