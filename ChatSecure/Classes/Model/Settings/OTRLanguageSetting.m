//
//  OTRLanguageSetting.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageSetting.h"
#import "OTRListSettingValue.h"
@import OTRAssets;

@interface OTRLanguageSetting ()

@end

@implementation OTRLanguageSetting

-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription settingsKey:(NSString *)newSettingsKey
{
    if (self = [super initWithTitle:newTitle description:newDescription settingsKey:newSettingsKey])
    {
        [self generatePossibleValues];
    }
    return self;
}

- (void)generatePossibleValues
{
    [self generatePossibleValues:[OTRLanguageManager supportedLanguages]];
}

- (void)generatePossibleValues:(NSArray *)languageCodes
{
    __block NSMutableArray *tempPossibleValues = [NSMutableArray arrayWithCapacity:[languageCodes count]];
    NSLocale *currentLocale = [[NSLocale alloc] initWithLocaleIdentifier:[OTRLanguageManager currentLocale]];
    
    [languageCodes enumerateObjectsUsingBlock:^(NSString *localeIdentifier, NSUInteger idx, BOOL *stop) {
        
        NSLocale *foreignLocale = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier];
        NSString *displayNameString = [[foreignLocale displayNameForKey:NSLocaleIdentifier value:localeIdentifier] capitalizedStringWithLocale:foreignLocale];
        NSString *detailNameString = [[currentLocale displayNameForKey:NSLocaleIdentifier value:localeIdentifier] capitalizedStringWithLocale:currentLocale];
        
        OTRListSettingValue *listSettingvalue = [[OTRListSettingValue alloc] initWithTitle:displayNameString detail:detailNameString value:localeIdentifier];
        [tempPossibleValues addObject:listSettingvalue];
    }];
    
    [tempPossibleValues sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 isKindOfClass:[OTRListSettingValue class]] && [obj2 isKindOfClass:[OTRListSettingValue class]]) {
            return [((OTRListSettingValue *)obj1).title localizedCaseInsensitiveCompare:((OTRListSettingValue *)obj2).title];
        }
        return NSOrderedSame;
    }];
    
    OTRListSettingValue *defaultValue = [[OTRListSettingValue alloc] initWithTitle:DEFAULT_LANGUAGE_STRING() detail:nil value:kOTRDefaultLanguageLocale];
    
    [tempPossibleValues insertObject:defaultValue atIndex:0];
    
    self.possibleValues = tempPossibleValues;
}

@end

