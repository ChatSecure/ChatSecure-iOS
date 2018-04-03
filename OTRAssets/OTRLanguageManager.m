//
//  OTRLanguageManager.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageManager.h"
#import "OTRAssets.h"
#import "OTRLanguageManager_Private.h"

static NSString *const kOTRAppleLanguagesKey  = @"AppleLanguages";

@implementation OTRLanguageManager

+(NSString *)currentLocale
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString *userSetting = [defaults objectForKey:kOTRSettingKeyLanguage];
     nil;
    NSArray *prefrences = nil;
    if ( [userSetting length] > 0 ) {
        prefrences = @[userSetting];
    }
    
    NSString *currentLocale = [[NSBundle preferredLocalizationsFromArray:[[OTRAssets resourcesBundle] localizations]
                                                          forPreferences:prefrences] firstObject];

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
    
    if (!bundlePath) {
        bundlePath = [bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:@"Base"];
    }
    NSBundle *foreignBundle = [[NSBundle alloc] initWithPath:[bundlePath stringByDeletingLastPathComponent]];
    NSString * translatedString = NSLocalizedStringFromTableInBundle(englishString, nil, foreignBundle, nil);
    
    if (![translatedString length]) {
        translatedString = englishString;
    }
    return translatedString;
}

@end
