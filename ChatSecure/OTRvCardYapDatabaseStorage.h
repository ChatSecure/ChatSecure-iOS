//
//  OTRvCardYapDatabaseStorage.h
//  Off the Record
//
//  Created by David Chiles on 4/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPvCardTempModule.h"
#import "XMPPvCardAvatarModule.h"

@interface OTRvCardYapDatabaseStorage : NSObject <XMPPvCardAvatarStorage,XMPPvCardTempModuleStorage>


@end
