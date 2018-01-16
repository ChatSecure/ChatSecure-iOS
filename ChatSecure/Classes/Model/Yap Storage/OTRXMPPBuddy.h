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

typedef SWIFT_ENUM(NSInteger, SubscriptionAttribute);
typedef SWIFT_ENUM(NSInteger, SubscriptionPendingAttribute);

/** Contains userInfo with buddy object in "buddy" key */
extern NSString * _Nonnull const OTRBuddyPendingApprovalDidChangeNotification;

typedef NS_ENUM(NSInteger, OTRXMPPBuddyTrustLevel) {
    OTRXMPPBuddyTrustLevelUntrusted = 0,
    OTRXMPPBuddyTrustLevelTrusted
};

@interface OTRXMPPBuddy : OTRBuddy <OTRvCard>

/** Returns the bare JID derived from the self.username property */
@property (nonatomic, strong, readonly, nullable) XMPPJID *bareJID;

@property (nonatomic) enum OTRXMPPBuddyTrustLevel trustLevel;
@property (nonatomic) SubscriptionAttribute subscription;
@property (nonatomic) SubscriptionPendingAttribute pending;

- (BOOL) subscribedTo;
- (BOOL) subscribedFrom;
- (BOOL) pendingApproval;
- (void) setPendingApproval:(BOOL)pending;
- (BOOL) askingForApproval;
- (void) setAskingForApproval:(BOOL)asking;

@end
