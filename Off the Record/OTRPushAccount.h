//
//  OTRPushAccount.h
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRPushObject.h"

@interface OTRPushAccount : OTRPushObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *email;


@end
