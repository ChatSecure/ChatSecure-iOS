//
//  OTRSetting.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/11/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSetting.h"

@implementation OTRSetting
@synthesize title, description, action, imageName;

- (void) dealloc
{
    title = nil;
    description = nil;
    self.action = nil;
    self.imageName = nil;
}

- (id) initWithTitle:(NSString*)newTitle description:(NSString*)newDescription
{
    if (self = [super init])
    {
        title = newTitle;
        description = newDescription;
        self.action = nil;
    }
    return self;
}

@end
