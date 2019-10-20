//
//  OTRSignalObject.m
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalObject.h"
#import "OTRAccount.h"

@implementation OTRSignalObject

/** Make sure if the account is deleted all the signal objects associated with that account 
 * are also removed from the database 
 */
- (nullable NSArray<YapDatabaseRelationshipEdge *> *)yapDatabaseRelationshipEdges
{
    YapDatabaseRelationshipEdge *accountEdge = [[YapDatabaseRelationshipEdge alloc] initWithName:@"" destinationKey:self.accountKey collection:[OTRAccount collection] nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
    if (accountEdge) {
        return @[accountEdge];
    }
    return nil;
}

@end
