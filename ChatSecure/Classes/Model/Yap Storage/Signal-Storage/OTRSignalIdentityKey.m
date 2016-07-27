//
//  OTRSignalIdentityKey.m
//  ChatSecure
//
//  Created by David Chiles on 7/26/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRSignalIdentityKey.h"

@implementation OTRSignalIdentityKey

- (instancetype)initWithAccountKey:(NSString *)accountKey name:(NSString *)name identityKey:(NSData *)identityKey
{
    if (self = [super initWithUniqueId:[[self class] uniqueKeyFromAccountKey:accountKey name:name]]) {
        self.accountKey = accountKey;
        self.name = name;
        self.identityKey = identityKey;
    }
    return self;
}

+ (NSString *)uniqueKeyFromAccountKey:(NSString *)accountKey name:(NSString *)name;
{
    return [NSString stringWithFormat:@"%@-%@",accountKey,name];
}

@end
