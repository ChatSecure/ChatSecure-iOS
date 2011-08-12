//
//  ANNickWInfo.m
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMNickWInfo.h"


@implementation AIMNickWInfo

@synthesize evil;
@synthesize username;
@synthesize userAttributes;

- (id)initWithData:(NSData *)nickWInfo {
	NSAssert(nickWInfo != nil, @"Cannot initialize a nil NickWInfo");
	const char * ptr = (const char *)[nickWInfo bytes];
	int length = (int)[nickWInfo length];
	if ((self = [self initWithPointer:ptr length:&length])) {
	}
	return self;
}

- (id)initWithPointer:(const char *)ptr length:(int *)_length {
	if ((self = [super init])) {
		if (*_length < 2) {
			[super dealloc];
			return nil;
		}
		int mlength = *_length;
		NSData * nickWInfo = [NSData dataWithBytes:ptr length:mlength];
		UInt8 length = *(const UInt8 *)[nickWInfo bytes];
		if (length + 1 >= [nickWInfo length]) {
			NSLog(@"NickWInfo Error: Length is too low for nick.");
			[super dealloc];
			return nil;
		}
		
		self.username = [[[NSString alloc] initWithBytes:&((const char *)[nickWInfo bytes])[1]
												  length:length
												encoding:NSUTF8StringEncoding] autorelease];
		
		if (length + 1 + 2 > [nickWInfo length]) {
			NSLog(@"NickWInfo Error: Length is too low for nick AND evil.");
			self.username = nil;
			[super dealloc];
			return nil;
		}
		
		evil = flipUInt16(*((const UInt16 *)(&((const char *)[nickWInfo bytes])[length + 1])));
		int index = length + 3;
		
		int addLength = (int)([nickWInfo length] - index);
		
		// we want a mutable version of this.
		NSArray * _userAttributes = [TLV decodeTLVBlock:&((const char *)[nickWInfo bytes])[index]
											 length:&addLength];
		if (!_userAttributes) addLength = 2;
		self.userAttributes = [NSMutableArray arrayWithArray:_userAttributes];
		
		*_length = index + addLength;
	}
	return self;
}

- (NSData *)encodePacket {
	NSMutableData * encoded = [[NSMutableData alloc] init];
	UInt16 flippedEvil = flipUInt16(evil);
	[encoded appendData:encodeString8(username)];
	[encoded appendBytes:&flippedEvil length:2];
	[encoded appendData:[TLV encodeTLVBlock:self.userAttributes]];
	
	// create immutable version
	NSData * immutableNickInfo = [NSData dataWithData:encoded];
	[encoded release];
	return immutableNickInfo;
}

+ (NSArray *)decodeArray:(NSData *)arrayOfNicks {
	NSMutableArray * list = [[NSMutableArray alloc] init];
	const char * bytes = [arrayOfNicks bytes];
	int index = 0;
	int totalLength = (int)[arrayOfNicks length];
	while (totalLength > 0) {
		int justUsed = totalLength;
		AIMNickWInfo * nick = [[AIMNickWInfo alloc] initWithPointer:&bytes[index] length:&justUsed];
		if (!nick) {
			[list release];
			[nick release];
			return nil;
		}
		[list addObject:nick];
		[nick release];
		index += justUsed;
		totalLength -= justUsed;
	}
	
	// create an immutable version
	NSArray * immutableNicks = [NSArray arrayWithArray:list];
	[list release];
	return immutableNicks;
}

- (UInt16)nickFlags {
	for (TLV * attr in self.userAttributes) {
		if ([attr type] == TLV_NICK_FLAGS) {
			if ([[attr tlvData] length] != 2) return 0;
			UInt16 data = *(const UInt16 *)[[attr tlvData] bytes];
			return flipUInt16(data);
		}
	}
	return 0;
}

- (TLV *)attributeOfType:(UInt16)_attribute {
	for (TLV * attribute in self.userAttributes) {
		if ([attribute type] == _attribute) return attribute;
	}
	return nil;
}

#pragma mark NSCopying

- (AIMNickWInfo *)copyWithZone:(NSZone *)zone {
	return [[AIMNickWInfo allocWithZone:zone] initWithData:[self encodePacket]];
}

- (AIMNickWInfo *)copy {
	return [[AIMNickWInfo alloc] initWithData:[self encodePacket]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeInt:evil forKey:@"evil"];
	[aCoder encodeObject:username forKey:@"username"];
	[aCoder encodeObject:userAttributes forKey:@"attributes"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super init])) {
		evil = [aDecoder decodeIntForKey:@"evil"];
		username = [[aDecoder decodeObjectForKey:@"username"] copy];
		userAttributes = [[NSMutableArray alloc] initWithArray:[aDecoder decodeObjectForKey:@"attributes"]];
	}
	return self;
}

- (BOOL)isEqual:(id)object {
	if (self == object) return YES;
	if ([object isKindOfClass:[self class]]) {
		AIMNickWInfo * bid = (AIMNickWInfo *)object;
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		BOOL eq = YES;
		if (![self.username isEqual:bid.username]) {
			eq = NO;
		}
		[pool drain];
		return eq;
	} else return NO;
}

- (void)dealloc {
	self.username = nil;
	self.userAttributes = nil;
	[super dealloc];
}

@end
