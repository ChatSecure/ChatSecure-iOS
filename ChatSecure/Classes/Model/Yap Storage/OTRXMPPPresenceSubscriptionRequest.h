//
//  OTRXMPPPresenceSubscriptionRequest.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

@import YapDatabase;

@class OTRXMPPAccount;

extern const struct OTRXMPPPresenceSubscriptionRequestAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *displayName;
	__unsafe_unretained NSString *jid;
} OTRXMPPPresenceSubscriptionRequestAttributes;

extern const struct OTRXMPPPresenceSubscriptionRequestRelationships {
	__unsafe_unretained NSString *accountUniqueId;
} OTRXMPPPresenceSubscriptionRequestRelationships;

extern const struct OTRXMPPPresenceSubscriptionRequestEdges {
	__unsafe_unretained NSString *account;
} OTRXMPPPresenceSubscriptionRequestEdges;

@interface OTRXMPPPresenceSubscriptionRequest : OTRYapDatabaseObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *jid;

@property (nonatomic, strong) NSString *accountUniqueId;


- (OTRXMPPAccount *)accountWithTransaction:(YapDatabaseReadTransaction *)transaction;


+ (instancetype)fetchPresenceSubscriptionRequestWithJID:(NSString *)jid accontUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction;

@end
