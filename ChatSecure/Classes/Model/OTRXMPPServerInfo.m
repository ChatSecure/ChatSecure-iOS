//
//  OTRXMPPServerInfo.m
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPServerInfo.h"

@implementation OTRXMPPServerInfo


- (BOOL)isTorDomain
{
    return [self.serverDomain rangeOfString:@".onion"].location != NSNotFound;
}

+ (NSArray *)defaultServerListIncludeTor:(BOOL)includeTor
{
    NSMutableArray *serverList = [[NSMutableArray alloc] init];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"xmppServers" ofType:@"plist"];
    NSArray *domains = [NSArray arrayWithContentsOfFile:filePath];
    for (NSDictionary *domainDictionary in domains) {
        OTRXMPPServerInfo *info = [[self alloc] initWithDictionary:domainDictionary error:nil];
        if (info) {
            BOOL isTor = [info isTorDomain];
            if (isTor && includeTor) {
                [serverList addObject:info];
            } else if (!isTor) {
                [serverList addObject:info];
            }
        }
    }
    return serverList;
}

@end
