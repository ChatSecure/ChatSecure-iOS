//
//  OTRLanguageManager.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageManager.h"
#import "OTRStrings.h"
#import "OTRAssets.h"

NSString *const kOTRSettingKeyLanguage                 = @"userSelectedSetting";
NSString *const kOTRDefaultLanguageLocale = @"kOTRDefaultLanguageLocale";
NSString *const kOTRAppleLanguagesKey  = @"AppleLanguages";

@implementation OTRLanguageManager

+(NSString *)currentLocale
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString *userSetting = [defaults objectForKey:kOTRSettingKeyLanguage];
    NSString *currentLocale = nil;
    
    //Check that there is a user setting and it's not the default locale
    if([userSetting length] && ![userSetting isEqualToString:kOTRDefaultLanguageLocale]) {
        currentLocale = userSetting;
    }
    else {
        currentLocale = [[defaults objectForKey:kOTRAppleLanguagesKey] objectAtIndex:0];
    }

    return currentLocale;
}

+ (NSArray *)supportedLanguages
{
    NSBundle *bundle = [OTRAssets resourcesBundle];
    NSParameterAssert(bundle != nil);
    NSMutableArray *supportedLanguages = [[bundle localizations] mutableCopy];
    //Strange Xcode 6 base localization
    [supportedLanguages removeObject:@"Base"];
    
    return supportedLanguages;
}

+ (void)setLocale:(NSString *)locale
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:locale forKey:kOTRSettingKeyLanguage];
    [defaults synchronize];
}

+(NSString *)translatedString:(NSString *)englishString
{
    NSString * currentLocale = [OTRLanguageManager currentLocale];
    NSBundle *bundle = [OTRAssets resourcesBundle];
    NSParameterAssert(bundle != nil);
    NSString *bundlePath = [bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:currentLocale];
    if (!bundlePath && [currentLocale length] > 2) {
        currentLocale = [currentLocale substringToIndex:2];
        bundlePath = [bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:currentLocale];
    }
    if (!bundlePath) {
        NSString *defaultLocale = @"en";
        bundlePath = [bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:defaultLocale];
    }
    NSBundle *foreignBundle = [[NSBundle alloc] initWithPath:[bundlePath stringByDeletingLastPathComponent]];
    NSString * translatedString = NSLocalizedStringFromTableInBundle(englishString, nil, foreignBundle, nil);
    
    if (![translatedString length]) {
        translatedString = englishString;
    }
    return translatedString;
    
}

@end
