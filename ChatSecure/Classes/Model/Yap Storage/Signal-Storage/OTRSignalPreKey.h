//
//  OTRSignalPreKey.h
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTRSignalPreKey : OTRSignalObject

@property (nonatomic) uint32_t keyId;
@property (nonatomic, strong, nullable) NSData *keyData;

- (nullable instancetype)initWithAccountKey:(NSString *)accountKey keyId:(uint32_t)keyId keyData:(nullable NSData *)keyData;

+ (NSString *)uniqueKeyForAccountKey:(NSString *)accountKey keyId:(uint32_t)keyId;

@end

NS_ASSUME_NONNULL_END