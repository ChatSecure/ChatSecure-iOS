//
//  OTRYapDatabaseObject.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

@import YapDatabase;
@import Mantle;

NS_ASSUME_NONNULL_BEGIN

@protocol OTRYapDatabaseObject <NSObject>

@property (nonatomic, readonly) NSString *uniqueId;

- (nullable instancetype)initWithUniqueId:(NSString *)uniqueId;

- (void)saveWithTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction;
- (void)removeWithTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction;

+ (nonnull NSString *)collection;

+ (nullable instancetype)fetchObjectWithUniqueID:(NSString*)uniqueID transaction:(YapDatabaseReadTransaction*)transaction;

@end

@interface OTRYapDatabaseObject : MTLModel <OTRYapDatabaseObject>

@end

NS_ASSUME_NONNULL_END
