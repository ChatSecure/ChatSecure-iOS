//
//  ANCGIHTTPParameterReader.m
//  CGITesting
//
//  Created by Alex Nichol on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ANCGIHTTPParameterReader.h"

@implementation NSString (httpparameters)

- (NSDictionary *)parseHTTPParaemters {
	NSCharacterSet * splits = [NSCharacterSet characterSetWithCharactersInString:@"?&"];
	NSArray * components = [self componentsSeparatedByCharactersInSet:splits];
	NSMutableDictionary * dictionary = [[NSMutableDictionary alloc] init];
	for (NSString * string in components) {
		NSRange index = [string rangeOfString:@"="];
		if (index.location != NSNotFound) {
			NSString * name = [string substringToIndex:index.location];
			NSString * contents = [string substringFromIndex:index.location + 1];
			id myValue;
			NSData * dataValue = [contents dataByRemovingEscapeCharacters];
			NSString * stringValue = [[NSString alloc] initWithData:dataValue 
														   encoding:NSASCIIStringEncoding];
			if (stringValue) {
				myValue = [stringValue autorelease];
			} else {
				myValue = dataValue;
			}
			
			[dictionary setObject:myValue forKey:name];
		}
	}
	return [dictionary autorelease];
}

@end

@implementation NSDictionary (httpparameters)

- (NSString *)encodeHTTPParameters {
	NSMutableString * returnValue = [[NSMutableString alloc] init];
	for (id key in self) {
		id object = [self objectForKey:key];
		if ([object isKindOfClass:[NSData class]]) {
			// encode it as data
			NSString * encoded = [(NSData *)object stringByEscapingEveryCharacter];
			if ([returnValue length] <= 0) {
				[returnValue appendFormat:@"%@=%@", key, encoded];
			} else {
				[returnValue appendFormat:@"&%@=%@", key, encoded];
			}
		} else if ([object isKindOfClass:[NSString class]]) {
			// encode it as ascii
			NSString * encoded = [(NSString *)object stringByEscapingAllAsciiCharacters];
			if ([returnValue length] <= 0) {
				[returnValue appendFormat:@"%@=%@", key, encoded];
			} else {
				[returnValue appendFormat:@"&%@=%@", key, encoded];
			}
		} else {
			// invalid data type
			NSLog(@"Cannot encode data type that was provided for encoding. Sorry.");
		}
	}
	return [returnValue autorelease];
}

@end

@implementation NSMutableDictionary (mhttpparameters)

- (NSMutableString *)encodeHTTPParameters {
	NSMutableString * returnValue = [[NSMutableString alloc] init];
	for (id key in self) {
		id object = [self objectForKey:key];
		if ([object isKindOfClass:[NSData class]]) {
			// encode it as data
			NSString * encoded = [(NSData *)object stringByEscapingEveryCharacter];
			if ([returnValue length] <= 0) {
				[returnValue appendFormat:@"%@=%@", key, encoded];
			} else {
				[returnValue appendFormat:@"&%@=%@", key, encoded];
			}
		} else if ([object isKindOfClass:[NSString class]]) {
			// encode it as ascii
			NSString * encoded = [(NSString *)object stringByEscapingAllAsciiCharacters];
			if ([returnValue length] <= 0) {
				[returnValue appendFormat:@"%@=%@", key, encoded];
			} else {
				[returnValue appendFormat:@"&%@=%@", key, encoded];
			}
		} else {
			// invalid data type
			NSLog(@"Cannot encode data type that was provided for encoding. Sorry.");
		}
	}
	return [returnValue autorelease];
}

@end

@implementation ANCGIHTTPParameterReader

+ (NSDictionary *)getAllHTTPParameters {
	char * requestMethod = getenv("REQUEST_METHOD");
	if (requestMethod) {
		NSString * _requestMethod = [[NSString stringWithFormat:@"%s", requestMethod] lowercaseString];
		NSString * queryString = nil;
		if ([_requestMethod isEqual:@"get"]) {
			// here we read query string
			char * qstring = getenv("QUERY_STRING");
			if (!qstring) {
				return nil;
			}
			queryString = [NSString stringWithFormat:@"%s", qstring];
		} else {
			// here we read stdin
			NSMutableString * myString = [NSMutableString string];
			int t;
			while ((t = fgetc(stdin)) != EOF) {
				[myString appendFormat:@"%c", (char)t];
			}
			queryString = myString;
		}
		return [queryString parseHTTPParaemters];
	} else {
		return nil;
	}
}

@end