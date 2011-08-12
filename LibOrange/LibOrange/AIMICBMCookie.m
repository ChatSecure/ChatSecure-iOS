//
//  AIMICBMClient.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMICBMCookie.h"


@implementation AIMICBMCookie

- (id)initWithCookieData:(const char *)theCookieData {
	if ((self = [super init])) {
		memcpy(cookieData, theCookieData, 8);
	}
	return self;
}
- (NSData *)cookieData {
	return [NSData dataWithBytes:cookieData length:8];
}

+ (AIMICBMCookie *)randomCookie {
	char data[8];
	int rand1 = (int)arc4random();
	int rand2 = (int)arc4random();
	memcpy(data, &rand1, 4);
	memcpy(&data[4], &rand2, 4);
	return [[[AIMICBMCookie alloc] initWithCookieData:data] autorelease];
}

- (BOOL)isEqualToCookie:(AIMICBMCookie *)otherCookie {
	if ([[self cookieData] isEqual:[otherCookie cookieData]]) return YES;
	else return NO;
}

@end
