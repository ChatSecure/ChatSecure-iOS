/*
 *  BasicStrings.m
 *  TalkToOscar
 *
 *  Created by Alex Nichol on 3/23/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "BasicStrings.h"

NSString * decodeString8 (NSData * string8Data) {
	if ([string8Data length] < 1) return nil;
	UInt8 length = *(const UInt8 *)[string8Data bytes];
	if (length + 1 > [string8Data length]) return nil;
	return [[[NSString alloc] initWithBytes:&((const char *)[string8Data bytes])[1]
									length:length
								  encoding:NSUTF8StringEncoding] autorelease];
}
NSString * decodeString16 (NSData * string16Data) {
	if ([string16Data length] < 2) return nil;
	UInt8 length = flipUInt16(*(const UInt16 *)[string16Data bytes]);
	if (length + 2 > [string16Data length]) return nil;
	return [[[NSString alloc] initWithBytes:&((const char *)[string16Data bytes])[2]
									 length:length
								   encoding:NSUTF8StringEncoding] autorelease];
}
NSData * encodeString8 (NSString * string) {
	if ([string length] > 0xFF) return nil;
	NSMutableData * encoded = [[NSMutableData alloc] init];
	NSData * stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
	UInt8 length = [stringData length];
	[encoded appendBytes:&length length:1];
	[encoded appendData:stringData];
	// create immuatble data.
	NSData * string8 = [NSData dataWithData:encoded];
	[encoded release];
	return string8;
}
NSData * encodeString16 (NSString * string) {
	if ([string length] > 0xFFFF) return nil;
	NSMutableData * encoded = [[NSMutableData alloc] init];
	NSData * stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
	UInt16 length = flipUInt16([stringData length]);
	[encoded appendBytes:&length length:2];
	[encoded appendData:stringData];
	// create immuatble data.
	NSData * string16 = [NSData dataWithData:encoded];
	[encoded release];
	return string16;
}
NSArray * decodeString8Array (NSData * string8Arr) {
	if ([string8Arr length] < 1) return nil;
	NSMutableArray * list = [NSMutableArray array];
	const char * bytes = (const char *)[string8Arr bytes];
	int length = (int)[string8Arr length];
	while (length > 1) {
		UInt8 nextLen = *(const UInt8 *)bytes;
		if (nextLen + 1 > length) break;
		NSString * str = [[NSString alloc] initWithBytes:&bytes[1] length:nextLen encoding:NSUTF8StringEncoding];
		if (!str) break;
		[list addObject:[str autorelease]];
		bytes = &bytes[nextLen + 1];
		length -= nextLen + 1;
	}
	return list;
}
