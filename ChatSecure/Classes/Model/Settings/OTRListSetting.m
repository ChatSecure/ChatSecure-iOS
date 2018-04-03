//
//  OTRListSetting.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRListSetting.h"
#import "OTRLanguageListSettingViewController.h"
#import "OTRListSettingValue.h"

@implementation OTRListSetting
@synthesize delegate = _delegate;
@synthesize defaultValue = _defaultValue;

-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        __weak typeof (self) weakSelf = self;
        self.actionBlock = ^void(id sender){
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf editValue];
        };
    }
    return self;
}

- (NSUInteger)indexOfValue:(id)value
{
    __block NSUInteger index = 0;
    [self.possibleValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[OTRListSettingValue class]]) {
            OTRListSettingValue *listSettingValue = (OTRListSettingValue *)obj;
            if ([listSettingValue.value isEqual:value]) {
                index = idx;
                *stop = YES;
            }
        }
    }];
    return index;
}

- (void) editValue {
    if(self.delegate && [self.delegate respondsToSelector:@selector(otrSetting:showDetailViewControllerClass:)]) {
        [self.delegate otrSetting:self showDetailViewControllerClass:[OTRLanguageListSettingViewController class]];
    }
}

-(void)setValue:(NSString *)newValue
{
    [super setValue:newValue];
    if(self.delegate && [self.delegate respondsToSelector:@selector(refreshView)]) {
        [self.delegate refreshView];
    }
    
}

@end
