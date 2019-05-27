//
//  NSString+ChatSecure.h
//  ChatSecure
//
//  Created by David Chiles on 12/16/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN
@interface NSString (ChatSecure)

- (nullable NSString *)otr_stringInitialsWithMaxCharacters:(NSUInteger)maxCharacters;

- (NSString *)otr_stringByRemovingNonEnglishCharacters;

/** Cleans up a JID from "user@example.com" -> "User" */
- (nullable NSString*) otr_displayName;

@end
NS_ASSUME_NONNULL_END
