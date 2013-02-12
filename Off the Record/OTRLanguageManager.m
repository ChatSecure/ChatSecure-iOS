//
//  OTRLanguageManager.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageManager.h"
#import "Strings.h"



@implementation OTRLanguageManager


-(id)init
{
    if(self = [super init])
    {
        NSArray * supportedLanguages = [[NSBundle mainBundle] localizations];
        NSMutableDictionary * newLookupDictionary = [NSMutableDictionary dictionary];
        
        for(NSString * locale in supportedLanguages)
        {
            NSLocale *frLocale = [[NSLocale alloc] initWithLocaleIdentifier:locale];
            NSString *displayNameString = [frLocale displayNameForKey:NSLocaleIdentifier value:locale];
            
            if([displayNameString respondsToSelector:@selector(capitalizedStringWithLocale:)])
                [newLookupDictionary setObject:locale forKey:[displayNameString capitalizedStringWithLocale:frLocale]];
            else
                [newLookupDictionary setObject:locale forKey:[displayNameString capitalizedString]];

        }
        
        self.languageLookupDictionary = [[NSDictionary alloc] initWithDictionary:newLookupDictionary];
        
    }
    return self;
    
}

-(NSString *)currentValue
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if(![defaults objectForKey:kOTRUserSetLanguageKey])
    {
        //default setting
        return DEFAULT_LANGUAGE_STRING;
    }
    NSString * locale = [defaults objectForKey:kOTRUserSetLanguageKey];
    NSString * val = [[self.languageLookupDictionary allKeysForObject:locale] objectAtIndex:0];
    return val;
    
}
+(NSString *)currentLocale
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:kOTRUserSetLanguageKey])
        return [defaults objectForKey:kOTRUserSetLanguageKey];

    NSString * locale = [[defaults objectForKey:kOTRAppleLanguagesKey] objectAtIndex:0];
    return locale;
}

-(NSArray *)supportedLanguages
{
    NSMutableArray *languages = [[NSMutableArray alloc] init];
    
    NSString * resourcePath = [[NSBundle mainBundle] pathForResource:@"supportedLanguages" ofType:@"plist" inDirectory:nil forLocalization:nil];
    NSArray * twoLetterLanguages = [NSArray arrayWithContentsOfFile:resourcePath];
    
    for(NSString * locale in twoLetterLanguages)
    {
        [languages addObject:[self languageNameForLocalization:locale]];
    }
    
    NSMutableArray * sortedLanguages =[[languages sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    [sortedLanguages insertObject:DEFAULT_LANGUAGE_STRING atIndex:0];
    
    return sortedLanguages;
}

-(NSString *)languageNameForLocalization:(NSString *)locale
{
    return [[self.languageLookupDictionary allKeysForObject:locale] objectAtIndex:0];
}

-(void)setLocale:(NSString *)locale
{
    if([locale isEqualToString:DEFAULT_LANGUAGE_STRING])
    {
        [self resetToDefaults];
    }
    else
    {
        
        NSString * newLocaleString = [self.languageLookupDictionary objectForKey:locale];
        
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        
        
        [defaults setObject:newLocaleString forKey:kOTRUserSetLanguageKey];
        [defaults synchronize];
    }
    
}

-(void)resetToDefaults
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:kOTRUserSetLanguageKey];
    
    [defaults synchronize];
}

+(NSString *)translatedString:(NSString *)englishString
{
    NSString * currentLocale = [OTRLanguageManager currentLocale];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:currentLocale];
    if (!bundlePath && currentLocale.length > 2) {
        currentLocale = [currentLocale substringToIndex:2];
        bundlePath = [[NSBundle mainBundle] pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:currentLocale];
        //NSLog(@"Bundle path is nil! Falling back to 2-character locale.");
    }
    if (!bundlePath) {
        NSString *defaultLocale = @"en";
        bundlePath = [[NSBundle mainBundle] pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:defaultLocale];
        //NSLog(@"Bundle path is nil! Falling back to english locale.");
    }
    NSBundle *foreignBundle = [[NSBundle alloc] initWithPath:[bundlePath stringByDeletingLastPathComponent]];
    //NSError * error = nil;
    //BOOL load = [foreignBundle loadAndReturnError:&error];
    NSString * translatedString = NSLocalizedStringFromTableInBundle(englishString, nil, foreignBundle, nil);
    
    return translatedString;
    
}

@end
