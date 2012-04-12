//
//  OTRSettingsGroup.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingsGroup.h"

@implementation OTRSettingsGroup
@synthesize title, settings;

- (void) dealloc
{
    title = nil;
    settings = nil;
}

- (id) initWithTitle:(NSString*)newTitle settings:(NSArray*)newSettings
{
    if (self = [super init])
    {
        title = newTitle;
        settings = newSettings;
    }
    return self;
}

@end
