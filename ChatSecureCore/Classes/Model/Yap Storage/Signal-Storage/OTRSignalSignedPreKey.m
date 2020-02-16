//
//  OTRSignalSignedPreKey.m
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalSignedPreKey.h"
#import "OTRAccount.h"
#import "ChatSecureCoreCompat-Swift.h"

@implementation OTRSignalSignedPreKey

- (instancetype) initWithAccountKey:(NSString *)accountKey keyId:(uint32_t)keyId keyData:(NSData *)keyData
{
    if (self = [super initWithUniqueId:accountKey]) {
        self.accountKey = accountKey;
        self.keyId = keyId;
        self.keyData = keyData;
    }
    return self;
}


- (nullable NSArray<YapDatabaseRelationshipEdge *> *)yapDatabaseRelationshipEdges
{
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameSignalSignedPreKey];
    YapDatabaseRelationshipEdge *edge = [YapDatabaseRelationshipEdge edgeWithName:edgeName destinationKey:self.accountKey collection:[OTRAccount collection] nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
    if (edge) {
        return @[edge];
    }
    return nil;
}

@end
