//
//  OTRLog.h
//  Off the Record
//
//  Created by David Chiles on 1/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "DDLog.h"
#if DEBUG
    static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
    static const int ddLogLevel = LOG_LEVEL_OFF;
#endif