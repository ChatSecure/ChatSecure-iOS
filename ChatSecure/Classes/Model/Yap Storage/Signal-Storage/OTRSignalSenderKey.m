//
//  OTRSignalSenderKey.m
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalSenderKey.h"

@implementation OTRSignalSenderKey

- (instancetype)initWithAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId groupId:(NSString *)groupId senderKey:(NSData *)senderKey
{
    if (self = [super initWithUniqueId:[[self class] uniqueKeyFromAccountKey:accountKey name:name deviceId:deviceId groupId:_groupId]]) {
        self.accountKey = accountKey;
        self.name = name;
        self.deviceId = deviceId;
        self.groupId = groupId;
        self.senderKey = senderKey;
    }
    return self;
}

+ (NSString *)uniqueKeyFromAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId groupId:(NSString *)groupId {
    return [NSString stringWithFormat:@"%@-%@-%d-%@",accountKey,name,deviceId,groupId];
}

@end
