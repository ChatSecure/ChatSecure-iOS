//
//  NSString+ChatSecure.m
//  ChatSecure
//
//  Created by David Chiles on 12/16/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "NSString+ChatSecure.h"

@implementation NSString (ChatSecure)

- (NSString *)otr_stringInitialsWithMaxCharacters:(NSUInteger)maxCharacters
{
    if (![self length]) {
        return nil;
    }
    
    if (maxCharacters == 1) {
        return [self substringToIndex:1];
    } else {
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" ._-+"];
        NSArray *splitArray = [self componentsSeparatedByCharactersInSet:characterSet];
        if ([splitArray count] > maxCharacters) {
            splitArray = [splitArray subarrayWithRange:NSMakeRange(0, maxCharacters)];
        }
        
        NSMutableString *finalString = [[NSMutableString alloc] init];
        [splitArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
            if ([obj length]) {
                [finalString appendString:[obj substringToIndex:1]];
            }
            
        }];
        
        return [finalString uppercaseString];
    }
}

@end
