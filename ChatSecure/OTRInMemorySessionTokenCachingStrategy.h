//
//  OTRInMemorySessionTokenCachingStrategy.h
//  ChatSecure
//
//  Created by David Chiles on 10/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "FBSessionTokenCachingStrategy.h"

@interface OTRInMemorySessionTokenCachingStrategy : FBSessionTokenCachingStrategy

- (instancetype)initWithToken:(FBAccessTokenData *)token;

@end
