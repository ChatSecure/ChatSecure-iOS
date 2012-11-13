//
//  OTRListSetting.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRListSetting.h"
#import "OTRListSettingViewController.h"

@implementation OTRListSetting

@synthesize possibleValues;
@synthesize defaultValue;

- (void)dealloc
{
    possibleValues = nil;
}


-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        self.action = @selector(editValue);
    }
    return self;
}

- (void) editValue {
    if(self.delegate && [self.delegate conformsToProtocol:@protocol(OTRSettingDelegate)]) {
        [self.delegate otrSetting:self showDetailViewControllerClass:[OTRListSettingViewController class]];
    }
}

-(NSString *)value
{
    if(![self value])
    {
        self.value = self.defaultValue;
    }
    return [self value];
}

@end
