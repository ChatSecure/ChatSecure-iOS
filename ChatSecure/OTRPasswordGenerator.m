//
//  OTRPasswordGenerator.m
//  ChatSecure
//
//  Created by David Chiles on 10/21/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPasswordGenerator.h"

NSUInteger const OTRDefaultPasswordLength = 100;

@implementation OTRPasswordGenerator

+ (NSString *)passwordWithLength:(NSUInteger)length
{
    NSString *alphaString = @"abcdefghijklmnopqrstuvwxyz";
    NSString *alphaUpperString = [alphaString uppercaseString];
    NSString *digitsString = @"0123456789";
    NSString *symbolsString = @"~!@#$%^&*+=?/|:;{}[]()-_,.";
    
    NSString *allCharacters = [NSString stringWithFormat:@"%@%@%@%@",alphaString,alphaUpperString,digitsString,symbolsString];
    NSUInteger allCharactersLength = [allCharacters length];
    
    NSMutableString *password = [NSMutableString new];
    for (int i = 0; i < length; i++) {
        NSUInteger index = arc4random() % allCharactersLength;
        [password appendFormat:@"%C",[allCharacters characterAtIndex:index]];
    }
    
    return password;
}

@end
