//
//  OTRYapDatabaseObject.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
#import "OTRLog.h"

@interface OTRYapDatabaseObject ()

@property (nonatomic, strong) NSString *uniqueId;

@end

@implementation OTRYapDatabaseObject
@synthesize uniqueId = _uniqueId;

- (id)init
{
    if (self = [super init])
    {
        self.uniqueId = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype)initWithUniqueId:(NSString *)uniqueId
{
    if (self = [super init]) {
        self.uniqueId = uniqueId;
    }
    return self;
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction setObject:self forKey:self.uniqueId inCollection:[[self class] collection]];
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction removeObjectForKey:self.uniqueId inCollection:[[self class] collection]];
}

/** This will fetch an updated instance of the object */
- (nullable instancetype)refetchWithTransaction:(nonnull YapDatabaseReadWriteTransaction *)transaction {
    id object = [[self class] fetchObjectWithUniqueID:self.uniqueId transaction:transaction];
    return object;
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([self class]);
}

+ (nullable instancetype) fetchObjectWithUniqueID:(NSString *)uniqueID transaction:(YapDatabaseReadTransaction *)transaction {
    NSParameterAssert(uniqueID);
    NSParameterAssert(transaction);
    if (!uniqueID || !transaction) {
        return nil;
    }
    id object = [transaction objectForKey:uniqueID inCollection:[self collection]];
    NSParameterAssert(!object || [object isKindOfClass:[self class]]);
    return object;
}

@end
