//
//  OTRLog.h
//  Off the Record
//
//  Created by David Chiles on 1/24/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import CocoaLumberjack;

#ifdef DEBUG
    static int ddLogLevel = DDLogLevelVerbose;
#else
    static int ddLogLevel = DDLogLevelOff;
#endif