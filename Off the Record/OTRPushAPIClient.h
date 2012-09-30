//
//  OTRPushAPIClient.h
//  Off the Record
//
//  Created by Christopher Ballinger on 9/29/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "AFHTTPClient.h"

@interface OTRPushAPIClient : AFHTTPClient

+ (OTRPushAPIClient*) sharedClient;

@end
