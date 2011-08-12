//
//  ANStringEscaper.h
//  SubmitToStore
//
//  Created by Alex Nichol on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (escaper)

- (NSString *)stringByEscapingAllAsciiCharacters;
- (NSString *)stringByRemovingEscapeCharacters;
- (NSData *)dataByRemovingEscapeCharacters;

@end

@interface NSData (escaper)

- (NSString *)stringByEscapingEveryCharacter;

@end