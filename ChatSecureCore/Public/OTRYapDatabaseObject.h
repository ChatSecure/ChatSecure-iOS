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

@protocol OTRYapDatabaseObjectProtocol <NSObject, NSSecureCoding, NSCopying>
@required

@property (nonatomic, readonly) NSString *uniqueId;
@property (class, readonly) NSString *collection;

- (void)touchWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
/** This will fetch an updated (copied) instance of the object. If nil, it means it was deleted or not present in the db. */
- (nullable instancetype)refetchWithTransaction:(YapDatabaseReadTransaction *)transaction;

+ (nullable instancetype)fetchObjectWithUniqueID:(NSString*)uniqueID transaction:(YapDatabaseReadTransaction*)transaction;

/// Shortcut for self.class.collection
- (NSString*) yapCollection;

@end

@interface OTRYapDatabaseObject : MTLModel <OTRYapDatabaseObjectProtocol>

- (instancetype)initWithUniqueId:(NSString *)uniqueId;

@end

NS_ASSUME_NONNULL_END
