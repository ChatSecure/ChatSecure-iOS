//
//  OTRPUSHHTTPRequestSerializer.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "AFURLRequestSerialization.h"

@interface OTRPUSHHTTPRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, strong) NSString *bearerToken;

@end
