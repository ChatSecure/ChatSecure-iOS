//
//  OTRYapPushTokenSent.h
//  Off the Record
//
//  Created by David Chiles on 5/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapPushToken.h"

@interface OTRYapPushTokenOwned : OTRYapPushToken

+ (instancetype)unusedPushTokenWithTransaction:(YapDatabaseReadTransaction *)transaction;

@end
