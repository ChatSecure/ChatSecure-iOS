//
//  OTRSignalSignedPreKey.h
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalObject.h"
@import YapDatabase;

NS_ASSUME_NONNULL_BEGIN

@interface OTRSignalSignedPreKey : OTRSignalObject <YapDatabaseRelationshipNode>

@property (nonatomic) uint32_t keyId;
@property (nonatomic, strong) NSData *keyData;

- (nullable instancetype)initWithAccountKey:(NSString *)accountKey keyId:(uint32_t)keyId keyData:(NSData *)keyData;

@end

NS_ASSUME_NONNULL_END