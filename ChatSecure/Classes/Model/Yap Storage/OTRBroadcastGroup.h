//
//  OTRGroups.h
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

@class OTRAccount, OTRMessage;

extern const struct OTRBroadcastGroupAttributes {
    __unsafe_unretained NSString *displayName;
    __unsafe_unretained NSString *composingMessageString;
    __unsafe_unretained NSString *buddies;
} OTRBroadcastGroupAttributes;

extern const struct OTRBroadcastGroupRelationships {
    __unsafe_unretained NSString *accountUniqueId;
} OTRBroadcastGroupRelationships;

extern const struct OTRBroadcastGroupEdges {
    __unsafe_unretained NSString *account;
} OTRBroadcastGroupEdges;


@interface OTRBroadcastGroup : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSMutableArray *buddies;
@property (nonatomic, strong) NSString *composingMessageString;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) NSString *accountUniqueId;

- (id)initWithBuddyArray:(NSMutableArray *)buddies;

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction;


@end