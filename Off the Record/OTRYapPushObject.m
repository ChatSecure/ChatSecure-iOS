//
//  OTRYapPushObject.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushObject.h"
#import "YapDatabaseTransaction.h"

@implementation OTRYapPushObject

- (instancetype)initWithUniqueId:(NSString *)uniqueId
{
    if (self = [self init]) {
        self.serverId = @([uniqueId intValue]);
    }
    return self;
}

- (NSString *)uniqueId
{
    return [self.serverId stringValue];
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction setObject:self forKey:self.uniqueId inCollection:[[self class] collection]];
}

+ (NSString *)collection
{
    return  NSStringFromClass([self class]);
}

+ (instancetype) fetchObjectWithUniqueID:(NSString*)uniqueID transaction:(YapDatabaseReadTransaction*)transaction
{
    [transaction objectForKey:uniqueID inCollection:[self collection]];
}

@end
