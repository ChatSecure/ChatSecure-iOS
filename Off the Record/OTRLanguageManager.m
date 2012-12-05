//
//  OTRLanguageManager.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageManager.h"
#import "Strings.h"

#define kOTRAppleLanguagesKey @"AppleLanguages"

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

            
            [newLookupDictionary setObject:locale forKey:[displayNameString capitalizedStringWithLocale:frLocale]];
        }
        
        self.languageLookupDictionary = [[NSDictionary alloc] initWithDictionary:newLookupDictionary];
        
    }
    return self;
    
}

-(NSString *)currentValue
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if([[defaults objectForKey:kOTRAppleLanguagesKey] isEqualToArray:[defaults objectForKey:kOTRLanguageDefaultArrayKey]])
    {
        //default setting
        return DEFAULT_LANGUAGE_STRING;
    }
    NSString * locale = [[defaults objectForKey:kOTRAppleLanguagesKey] objectAtIndex:0];
    NSString * val = [[self.languageLookupDictionary allKeysForObject:locale] objectAtIndex:0];
    return val;
    
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
    
    NSMutableArray * finalLanguages = [[NSMutableArray alloc] initWithArray:[languages sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    [finalLanguages insertObject:DEFAULT_LANGUAGE_STRING atIndex:0];
    
    return finalLanguages;
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
        NSMutableArray * newLocalesArray = [[NSMutableArray alloc] init];
        
        NSString * newLocaleString = [self.languageLookupDictionary objectForKey:locale];
        
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        
        if([defaults objectForKey:kOTRLanguageDefaultArrayKey])
        {
            [newLocalesArray addObjectsFromArray:[defaults objectForKey:kOTRLanguageDefaultArrayKey]];
            [newLocalesArray removeObject:newLocaleString];
            [newLocalesArray insertObject:newLocaleString atIndex:0];
        }
        
        
        [defaults setObject:newLocalesArray forKey:kOTRAppleLanguagesKey];
        [defaults synchronize];
    }
    
}

-(void)resetToDefaults
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:kOTRLanguageDefaultArrayKey])
    {
        [defaults setObject:[defaults objectForKey:kOTRLanguageDefaultArrayKey] forKey:kOTRAppleLanguagesKey];
    }
    [defaults synchronize];
}

+(void)saveDefaultLanguageArray
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * languageArray = [defaults objectForKey:kOTRAppleLanguagesKey];
    [defaults setObject:languageArray forKey:kOTRLanguageDefaultArrayKey];
    [defaults synchronize];
}

+(BOOL)defaultLanguagesSaved
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kOTRLanguageDefaultArrayKey])
        return YES;
    return NO;
}

@end
