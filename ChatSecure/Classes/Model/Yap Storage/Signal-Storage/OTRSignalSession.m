//
//  OTRSignalSession.m
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalSession.h"

@implementation OTRSignalSession

- (nullable instancetype)initWithAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId sessionData:(NSData *)sessionData
{
    NSString *yapKey = [[self class] uniqueKeyForAccountKey:accountKey name:name deviceId:deviceId];
    if (self = [super initWithUniqueId:yapKey] ) {
        self.accountKey = accountKey;
        self.name = name;
        self.deviceId = deviceId;
        self.sessionData = sessionData;
    }
    return self;
}

+ (NSString *)uniqueKeyForAccountKey:(NSString *)accountKey name:(NSString *)name deviceId:(int32_t)deviceId
{
    return [NSString stringWithFormat:@"%@-%@-%d",accountKey,name,deviceId];
}

@end
