//
//  OTRLog.h
//  Off the Record
//
//  Created by David Chiles on 1/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "DDLog.h"

#ifdef DEBUG
    static int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    static int ddLogLevel = LOG_LEVEL_OFF;
#endif