//
//  OTRSignalSession.h
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface OTRSignalSession : OTRSignalObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic) int32_t deviceId;
@property (nonatomic, strong) NSData *sessionData;

- (nullable instancetype)initWithAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId sessionData:(NSData *)sessionData;

+ (NSString *)uniqueKeyForAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId;

@end

NS_ASSUME_NONNULL_END
