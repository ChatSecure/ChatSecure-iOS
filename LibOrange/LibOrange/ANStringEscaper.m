//
//  ANStringEscaper.m
//  SubmitToStore
//
//  Created by Alex Nichol on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ANStringEscaper.h"

static int htoi (const char * s) {
	const char * t = s;
	int x = 0, y = 1;
	if (*s == '0' && (s[1] == 'x' || s[1] == 'X'))
		t += 2;
	s += strlen(s);
	while (t <= --s) {
		if ('0' <= *s && *s <= '9')
			x+=y * (*s - '0');
		else if ('a' <= *s && *s <= 'f')
			x+=y * (*s - 'a' + 10);
		else if ('A' <= *s && *s <= 'F')
			x+=y * (10 + *s - 'A');
		else
			return -1; /* invalid input! */
		y <<= 4;
	}
	return x;
}

@implementation NSString (escaper)


- (NSString *)stringByEscapingAllAsciiCharacters {
	NSMutableString * returnValue = [NSMutableString stringWithFormat:@""];

	for (int i = 0; i < [self length]; i++) {
		char c = [self characterAtIndex:i];
		if (!isascii(c) || c == '?' || c == '&' || c == '/' || c == '=' || 
			c == '+' || c == ' ' || isspecial(c) || c == ':' || c == '%') {
			NSString * value = [[NSString stringWithFormat:@"%%%02x", c] uppercaseString];
			[returnValue appendFormat:@"%@", value];
		} else [returnValue appendFormat:@"%c", c];
	}
	
	return returnValue;
}

- (NSString *)stringByRemovingEscapeCharacters {
	NSMutableString * returnValue = [NSMutableString stringWithFormat:@""];
	for (int i = 0; i < [self length]; i++) {
		char c = [self characterAtIndex:i];
		if (c == '%') {
			if (i + 2 < [self length]) {
				NSString * hexValue = [self substringWithRange:NSMakeRange(i+1, 2)];
				// process this later
				int cd = htoi([[@"0x" stringByAppendingFormat:@"%@", hexValue] UTF8String]);
				[returnValue appendFormat:@"%c", (char)cd];
				i += 2;
			}
		} else {
			[returnValue appendFormat:@"%c", c];
		}
	}
	return returnValue;
}

- (NSData *)dataByRemovingEscapeCharacters {
	NSMutableData * returnValue = [[NSMutableData alloc] init];
	for (int i = 0; i < [self length]; i++) {
		char c = [self characterAtIndex:i];
		if (c == '%') {
			if (i + 2 < [self length]) {
				NSString * hexValue = [self substringWithRange:NSMakeRange(i+1, 2)];
				// process this later
				char cd = (char)htoi([[@"0x" stringByAppendingFormat:@"%@", hexValue] UTF8String]);
				[returnValue appendBytes:&cd length:1];
				i += 2;
			}
		} else {
			[returnValue appendBytes:&c length:1];
		}
	}
	return [returnValue autorelease];
}

@end

@implementation NSData (escaper)

- (NSString *)stringByEscapingEveryCharacter {
	NSMutableString * returnValue = [NSMutableString stringWithFormat:@""];
	
	for (int i = 0; i < [self length]; i++) {
		char c = ((const char *)[self bytes])[i];
		if (!isalnum(c)) {
			[returnValue appendFormat:@"%%%02x", c];
		} else [returnValue appendFormat:@"%c", c];
	}
	
	return returnValue;
}

@end