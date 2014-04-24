//
//  OTRPushToken.h
//  Off the Record
//
//  Created by David Chiles on 4/22/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPushObject.h"

@interface OTRPushToken : OTRPushObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *token;

@end
