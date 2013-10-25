//
//  OTRvCardCoreDataStorage.h
//  Off the Record
//
//  Created by David Chiles on 10/24/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPvCardTempModule.h"
#import "XMPPvCardAvatarModule.h"

@interface OTRvCardCoreDataStorage : NSObject <XMPPvCardAvatarStorage,XMPPvCardTempModuleStorage>



@end
