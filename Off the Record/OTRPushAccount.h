//
//  OTRPushAccount.h
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRAccount.h"


@interface OTRPushAccount : OTRAccount

@property (nonatomic) BOOL isRegistered;

+ (OTRPushAccount*) activeAccount;

@end
