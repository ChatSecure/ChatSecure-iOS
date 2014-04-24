//
//  OTRPushOAuth2Client.m
//  Off the Record
//
//  Created by David Chiles on 4/23/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushOAuth2Client.h"


@interface OTRPushOAuth2Client ()

@end

@implementation OTRPushOAuth2Client

- (void)authenticateUsingUsername:(NSString *)username
                         password:(NSString *)password
                          success:(void(^)(AFOAuthCredential *credential))successBlock
                          failure:(void(^)(NSError *error))failureBlock
{
    NSString *urlString = [NSString stringWithFormat:@"%@%@",[self.baseURL absoluteString],@"/o/token/"];
    
    [self authenticateUsingOAuthWithURLString:urlString username:username password:password scope:nil success:^(AFOAuthCredential *credential) {
        if (successBlock) {
            successBlock(credential);
        }
    } failure:^(NSError *error) {
        if (failureBlock) {
            failureBlock(error);
        }
    }];
}

- (void)authenticateUsingRefreshToken:(NSString *)refreshToken
                              success:(void (^)(AFOAuthCredential *credential))success
                              failure:(void (^)(NSError *error))failure
{
    NSString *urlString = [NSString stringWithFormat:@"%@%@",[self.baseURL absoluteString],@"/o/token/"];
    
    [self authenticateUsingOAuthWithURLString:urlString refreshToken:refreshToken success:^(AFOAuthCredential *credential) {
        if (success) {
            success(credential);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end
