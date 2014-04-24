//
//  OTRPUSHHTTPRequestSerializer.m
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPUSHHTTPRequestSerializer.h"

@implementation OTRPUSHHTTPRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(NSDictionary *)parameters
                                        error:(NSError *__autoreleasing *)error
{
    request = [super requestBySerializingRequest:request withParameters:parameters error:error];
    
    if ([self.bearerToken length]) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [mutableRequest setValue:[@"Bearer " stringByAppendingString:self.bearerToken] forHTTPHeaderField:@"Authorization"];
        request = [mutableRequest copy];
    }
    return request;
}

@end
