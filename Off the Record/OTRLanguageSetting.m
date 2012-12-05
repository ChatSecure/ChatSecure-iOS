//
//  OTRLanguageSetting.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageSetting.h"

@implementation OTRLanguageSetting

@synthesize possibleValues;
@synthesize defaultValue;
@synthesize languageManager;
@synthesize value;


-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        languageManager = [[OTRLanguageManager alloc] init];
        self.possibleValues = [languageManager supportedLanguages];
        //self.defaultValue = [languageManager currentValue];
    }
    return self;
}

-(void)setValue:(id)newValue
{
    [super setValue:newValue];
    [languageManager setLocale:newValue];
}

-(NSString *)value
{
    if(![super value])
    {
        return [languageManager currentValue];
    }
    return [super value];
    
}

@end

