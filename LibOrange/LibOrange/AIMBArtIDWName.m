//
//  AIMBArtIDWName.m
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBArtIDWName.h"


@implementation AIMBArtIDWName

@synthesize bartIDs;
@synthesize username;

- (id)initWithNick:(NSString *)uname bartIds:(NSArray *)barts {
	if ((self = [super init])) {
		username = [uname retain];
		bartIDs = [barts retain];
	}
	return self;
}

- (id)initWithData:(NSData *)data {
	const char * bytes = [data bytes];
	int len = (int)[data length];
	if ((self = [self initWithPointer:bytes length:&len])) {
		
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)length {
	if ((self = [super init])) {
		if (*length < 2) {
			[super dealloc];
			return nil;
		}
		UInt8 loginIDLen = *(const UInt8 *)ptr;
		if (loginIDLen + 2 > *length) {
			[super dealloc];
			return nil;
		}
		username = [[NSString alloc] initWithBytes:&ptr[1] length:loginIDLen encoding:NSUTF8StringEncoding];
		UInt8 numIds = *(const UInt8 *)(&ptr[loginIDLen + 1]);
		const char * start = &ptr[loginIDLen + 2];
		int remaining = *length - (loginIDLen + 2);
		NSMutableArray * bartIdArray = [[NSMutableArray alloc] init];
		while (remaining > 0) {
			int used = remaining;
			AIMBArtID * bid = [[AIMBArtID alloc] initWithPointer:start length:&used];
			if (!bid) {
				[username release];
				[bartIdArray release];
				[super dealloc];
				return nil;
			}
			[bartIdArray addObject:bid];
			[bid release];
			start = &start[used];
			remaining -= used;
			if ([bartIdArray count] == numIds) break;
		}
		bartIDs = [[NSArray alloc] initWithArray:bartIdArray];
		[bartIdArray release];
		*length = *length - remaining;
	}
	return self;
}

- (NSData *)encodePacket {
	UInt8 numIds = (UInt8)[bartIDs count];
	UInt8 nameLen = (UInt8)[username length];
	NSMutableData * encoded = [[NSMutableData alloc] init];
	[encoded appendBytes:&nameLen length:1];
	[encoded appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];
	[encoded appendBytes:&numIds length:1];
	for (AIMBArtID * bid in bartIDs) {
		[encoded appendData:[bid encodePacket]];
	}
	
	NSData * immutable = [NSData dataWithData:encoded];
	[encoded release];
	return immutable;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:bartIDs forKey:@"bids"];
	[aCoder encodeObject:username forKey:@"username"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	NSString * nick = [aDecoder decodeObjectForKey:@"username"];
	NSArray * bids = [aDecoder decodeObjectForKey:@"bids"];
	if ((self = [self initWithNick:nick bartIds:bids])) {
		
	}
	return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[AIMBArtIDWName allocWithZone:zone] initWithData:[self encodePacket]];
}

- (void)dealloc {
	[username release];
	[bartIDs release];
	[super dealloc];
}

@end
