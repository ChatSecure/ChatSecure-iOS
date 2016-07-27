//
//  OTRSignalIdentityKey.h
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTRSignalIdentityKey : OTRSignalObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSData *identityKey;

- (nullable instancetype)initWithAccountKey:(NSString *)accountKey name:(NSString *)name identityKey:(NSData *)identityKey;

+ (NSString *)uniqueKeyFromAccountKey:(NSString *)accountKey name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END