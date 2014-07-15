//
//  OTRFacebookSessionCachingStrategy.h
//  Off the Record
//
//  Created by David on 9/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <FBSessionTokenCachingStrategy.h>

@interface OTRFacebookSessionCachingStrategy : FBSessionTokenCachingStrategy

@property (nonatomic,strong) NSDictionary * tokenDictionary;

- (id)initWithTokenDictionary:(NSDictionary *)tokenDictionary;

+ (id)createWithTokenDictionary:(NSDictionary *)tokenDictionary;

@end
