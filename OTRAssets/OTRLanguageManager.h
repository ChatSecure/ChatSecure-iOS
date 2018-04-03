//
//  OTRLanguageManager.h
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface OTRLanguageManager : NSObject

/**
 @return an Array of supported language codes from the bundle
 */
+ (NSArray<NSString*> *)supportedLanguages;

+ (void)setLocale:(NSString *)locale;
+ (NSString *)currentLocale;


@end
NS_ASSUME_NONNULL_END
