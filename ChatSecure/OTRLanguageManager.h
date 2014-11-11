//
//  OTRLanguageController.h
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kOTRDefaultLanguageLocale;

@interface OTRLanguageManager : NSObject

@property (nonatomic,strong) NSDictionary * languageLookupDictionary;

/**
 @return an Array of supported language codes from the bundle
 */
+ (NSArray *)supportedLanguages;

+ (void)setLocale:(NSString *)locale;

+ (NSString *)currentLocale;

+ (NSString *)translatedString:(NSString *)englishString;

@end
