//
//  OTRGroups.h
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

@class OTRAccount, OTRMessage;

extern const struct OTRGroupAttributes {
    __unsafe_unretained NSString *displayName;
} OTRGroupAttributes;

extern const struct OTRGroupRelationships {
    __unsafe_unretained NSString *accountUniqueId;
} OTRGroupRelationships;

extern const struct OTRGroupEdges {
    __unsafe_unretained NSString *account;
} OTRGroupEdges;


@interface OTRGroup : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *displayName;

@property (nonatomic, strong) NSString *accountUniqueId;

- (id)initWithGroupName:(NSString*) groupName;

+ (instancetype)fetchGroupWithGroupName:(NSString *)name
                   withAccountUniqueId:(NSString *)accountUniqueId
                           transaction:(YapDatabaseReadTransaction *)transaction;



@end