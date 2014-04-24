//
//  OTRPushOAuth2Client.h
//  Off the Record
//
//  Created by David Chiles on 4/23/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFOAuth2Client.h"

@class AFOAuthCredential;

@interface OTRPushOAuth2Client : AFOAuth2Client

- (void)authenticateUsingUsername:(NSString *)username
                         password:(NSString *)password
                          success:(void(^)(AFOAuthCredential *credential))successBlock
                          failure:(void(^)(NSError *error))failureBlock;

- (void)authenticateUsingRefreshToken:(NSString *)refreshToken
                              success:(void (^)(AFOAuthCredential *credential))success
                              failure:(void (^)(NSError *error))failure;

@end
