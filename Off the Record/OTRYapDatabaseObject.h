//
//  OTRYapDatabaseObject.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YapDatabaseRelationshipNode.h"
#import "YapDatabaseTransaction.h"

extern const struct OTRYapDatabaseObjectAttributes {
	__unsafe_unretained NSString *uniqueId;
} OTRYapDatabaseObjectAttributes;

@interface OTRYapDatabaseObject : NSObject <NSCoding, NSCopying, YapDatabaseRelationshipNode>

@property (nonatomic, readonly) NSString *uniqueId;

- (instancetype)initWithUniqueId:(NSString *)uniqueId;

+ (NSString *)collection;

+ (instancetype) fetchObjectWithUniqueID:(NSString*)uniqueID transaction:(YapDatabaseReadTransaction*)transaction;

@end
