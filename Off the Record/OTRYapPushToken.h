//
//  OTRYapPushToken.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

extern const struct OTRYapPushTokenEdges {
	__unsafe_unretained NSString *account;
    __unsafe_unretained NSString *buddy;
    
} OTRYapPushTokenEdges;

@interface OTRYapPushToken : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *token;

@property (nonatomic, strong) NSString *accountUniqueId;
@property (nonatomic, strong) NSString *buddyUniqueId;

+ (OTRYapPushToken *)tokenWithTokenString:(NSString *)tokenString transaction:(YapDatabaseReadTransaction *)transaction;

@end
