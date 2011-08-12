//
//  CommandTokenizer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CommandTokenizer.h"


@implementation CommandTokenizer

- (id)initWithString:(NSString *)command {
	if ((self = [super init])) {
		remaining = [command retain];
	}
	return self;
}
- (NSString *)nextToken {
	NSMutableString * token = [NSMutableString stringWithString:@""];
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	BOOL inQuotes = NO;
	int i;
	for (i = 0; i < [remaining length]; i++) {
		char c = (char)[remaining characterAtIndex:i];
		if (c == '"') {
			inQuotes ^= 1;
		} else if (c == ' ' && !inQuotes && [token length] > 0) {
			break;
		} else if (!(c == ' ' && [token length] == 0)) {
			[token appendFormat:@"%c", c];
		}
	}
	if (i == [remaining length]) {
		[pool drain];
		[remaining release];
		remaining = nil;
		return token;
	}
	[remaining autorelease];
	remaining = [[remaining substringFromIndex:i] retain];
	[pool drain];
	return token;
}
- (void)dealloc {
	[remaining release];
	[super dealloc];
}

+ (NSArray *)tokensOfCommand:(NSString *)command {
	NSMutableArray * tokens = [NSMutableArray array];
	CommandTokenizer * tokenizer = [[CommandTokenizer alloc] initWithString:command];
	NSString * astr = nil;
	while ((astr = [tokenizer nextToken])) {
		if ([astr length] == 0) break;
		[tokens addObject:astr];
	}
	[tokenizer release];
	return tokens;
}

@end
