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
            
            [newLookupDictionary setObject:locale forKey:displayNameString];
        }
        
        self.languageLookupDictionary = [[NSDictionary alloc] initWithDictionary:newLookupDictionary];
        
    }
    return self;
    
}

-(NSString *)currentValue
{
    return DEFAULT_LANGUAGE_STRING;
    
}

-(NSArray *)supportedLanguages
{
    NSMutableArray *languages = [NSMutableArray arrayWithArray:[self.languageLookupDictionary allKeys]];
    
    //[languages insertObject:DEFAULT_LANGUAGE_STRING atIndex:0];
    
    
    return languages;
}

-(void)setLocale:(NSString *)locale
{
    NSArray * newLocales;
   
    newLocales = [NSArray arrayWithObject:[self.languageLookupDictionary objectForKey:locale]];
    
    [[NSUserDefaults standardUserDefaults] setObject:newLocales forKey:@"AppleLanguages"];
}

@end
