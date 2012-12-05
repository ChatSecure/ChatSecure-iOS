//
//  OTRLanguageController.h
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kOTRAppleLanguagesKey @"AppleLanguages"
#define kOTRLanguageDefaultArrayKey @"kOTRLanguageDefaultArrayKey"
#define kOTRLanguageDefaultKey @"kOTRLanguageDefaultKey"
#define kOTRUserSetLanguageKey @"userSetLanguageKey"

@interface OTRLanguageManager : NSObject

@property (nonatomic,strong) NSDictionary * languageLookupDictionary;


-(NSArray *)supportedLanguages;
-(void)setLocale:(NSString *)locale;
-(NSString *)currentValue;
+(NSString *)currentLocale;
+(void)saveDefaultLanguageArray;
+(BOOL)defaultLanguagesSaved;
+(NSString *)translatedString:(NSString *)englishString;

@end
