//
//  OTRYapDatabaseObject.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

const struct OTRYapDatabaseObjectAttributes OTRYapDatabaseObjectAttributes = {
	.uniqueId = @"uniqueId"
};

@interface OTRYapDatabaseObject ()

@property (nonatomic, strong) NSString *uniqueId;

@end

@implementation OTRYapDatabaseObject

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

#pragma - mark Class Methods

+ (NSString *)collection
{
    return NSStringFromClass([self class]);
}

+ (instancetype) fetchObjectWithUniqueID:(NSString *)uniqueID transaction:(YapDatabaseReadTransaction *)transaction {
    return [transaction objectForKey:uniqueID inCollection:[self collection]];
}

@end
