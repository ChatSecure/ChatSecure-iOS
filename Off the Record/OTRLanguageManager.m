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

            if ([displayNameString respondsToSelector:@selector(capitalizedStringWithLocale:)]) { // only supported on iOS 6+
                [newLookupDictionary setObject:locale forKey:[displayNameString capitalizedStringWithLocale:frLocale]];
            } else {
                [newLookupDictionary setObject:locale forKey:[displayNameString capitalizedString]];
            }

        }
        
        self.languageLookupDictionary = [[NSDictionary alloc] initWithDictionary:newLookupDictionary];
        
    }
    return self;
    
}

-(NSString *)currentValue
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * locale = [[defaults objectForKey:@"AppleLanguages"] objectAtIndex:0];
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
    
    return [languages sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

-(NSString *)languageNameForLocalization:(NSString *)locale
{
    return [[self.languageLookupDictionary allKeysForObject:locale] objectAtIndex:0];
}

-(void)setLocale:(NSString *)locale
{
    NSMutableArray * newLocales;
   
    newLocales = [NSMutableArray arrayWithObject:[self.languageLookupDictionary objectForKey:locale]];
    
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    if([defaults objectForKey:kOTRLanguageDefaultArrayKey])
        [newLocales addObjectsFromArray:[defaults objectForKey:kOTRLanguageDefaultArrayKey]];
    
    [defaults setObject:newLocales forKey:@"AppleLanguages"];
    [defaults synchronize];
}

+(void)saveDefaultLanguageArray
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * languageArray = [defaults objectForKey:@"AppleLanguages"];
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
