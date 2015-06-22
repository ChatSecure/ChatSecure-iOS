//
//  OTRXMPPServerInfo.h
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "MTLModel.h"

@interface OTRXMPPServerInfo : MTLModel

@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) NSString *serverDomain;
@property (nonatomic, strong) NSString *userDomain;
@property (nonatomic, strong) NSString *serverImage;


+ (NSArray *)defaultServerListIncludeTor:(BOOL)includeTor;

@end
