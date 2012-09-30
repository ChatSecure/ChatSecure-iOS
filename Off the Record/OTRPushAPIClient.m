//
//  OTRPushAPIClient.m
//  Off the Record
//
//  Created by Christopher Ballinger on 9/29/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRPushAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "OTRPushController.h"

@implementation OTRPushAPIClient

+ (OTRPushAPIClient *)sharedClient {
    static OTRPushAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[OTRPushAPIClient alloc] initWithBaseURL:[OTRPushController baseURL]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    self.parameterEncoding = AFJSONParameterEncoding;
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

@end
