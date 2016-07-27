//
//  OTRSignalSenderKey.h
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTRSignalSenderKey : OTRSignalObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic) int32_t deviceId;
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSData *senderKey;

- (nullable instancetype)initWithAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId groupId:(NSString *)groupId senderKey:(NSData *)senderKey;

+ (NSString *)uniqueKeyFromAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId groupId:(NSString *)groupId;

@end

NS_ASSUME_NONNULL_END