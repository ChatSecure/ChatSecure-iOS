//
//  OTRXMPPBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
@import UIKit;

@class OTRBuddy, OTRGroup;

extern const struct OTRBuddyGroupAttributes {
} OTRBuddyGroupAttributes;
    
extern const struct OTRBuddyGroupRelationships {
    __unsafe_unretained NSString *buddyUniqueId;
    __unsafe_unretained NSString *groupUniqueId;
} OTRBuddyGroupRelationships;

extern const struct OTRBuddyGroupEdges {
    __unsafe_unretained NSString *buddy;
    __unsafe_unretained NSString *group;
} OTRBuddyGroupBuddyEdges;


@interface OTRBuddyGroup : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *groupUniqueId;
@property (nonatomic, strong) NSString *buddyUniqueId;


+ (instancetype)fetchBuddyGroupWithBuddyUniqueId:(NSString *)buddyUniqueId
                          withGroupUniqueId:(NSString *)groupUniqueId
                          transaction:(YapDatabaseReadTransaction *)transaction;


@end
