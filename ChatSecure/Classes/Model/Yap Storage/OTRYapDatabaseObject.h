//
//  OTRYapDatabaseObject.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@import YapDatabase;
@import Mantle;

@interface OTRYapDatabaseObject : MTLModel

@property (nonatomic, readonly, nonnull) NSString *uniqueId;

- (nonnull instancetype)initWithUniqueId:(nonnull NSString *)uniqueId;

- (void)saveWithTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction;
- (void)removeWithTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction;

+ (nonnull NSString *)collection;

+ (nullable instancetype)fetchObjectWithUniqueID:(nonnull NSString*)uniqueID transaction:(nonnull YapDatabaseReadTransaction*)transaction;

@end
