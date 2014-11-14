//
//  OTRLanguageManager.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageManager.h"
#import "Strings.h"
#import "OTRConstants.h"

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
    NSMutableArray *supportedLanguages = [[[NSBundle mainBundle] localizations] mutableCopy];
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
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:currentLocale];
    if (!bundlePath && [currentLocale length] > 2) {
        currentLocale = [currentLocale substringToIndex:2];
        bundlePath = [[NSBundle mainBundle] pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:currentLocale];
    }
    if (!bundlePath) {
        NSString *defaultLocale = @"en";
        bundlePath = [[NSBundle mainBundle] pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:defaultLocale];
    }
    NSBundle *foreignBundle = [[NSBundle alloc] initWithPath:[bundlePath stringByDeletingLastPathComponent]];
    NSString * translatedString = NSLocalizedStringFromTableInBundle(englishString, nil, foreignBundle, nil);
    
    if (![translatedString length]) {
        translatedString = englishString;
    }
    return translatedString;
    
}

@end
