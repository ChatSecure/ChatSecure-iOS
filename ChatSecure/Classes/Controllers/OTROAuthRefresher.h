//
//  OTROAuthRefresher.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

@class GTMOAuth2Authentication;
@class FBAccessTokenData;
@class OTROAuthXMPPAccount;

typedef void(^OTROAuthCompletionBlock)(id token,NSError *);

@interface OTROAuthRefresher : NSObject

+ (void)refreshAccount:(OTROAuthXMPPAccount *)account completion:(OTROAuthCompletionBlock)completionBlock;

@end
