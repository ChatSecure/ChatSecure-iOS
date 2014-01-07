//
//  OTRRosterStorage.h
//  Off the Record
//
//  Created by David on 10/18/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPRoster.h"

@interface OTRRosterStorage : NSObject <XMPPRosterStorage>
{
    BOOL isPopulatingRoster;
}

@end
