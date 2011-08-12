//
//  NSMutableData+FlipBit.m
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSMutableData+FlipBit.h"


@implementation NSMutableData (FlipBit)

- (void)appendNetworkOrderUInt16:(UInt16)nonNetworkOrder {
	UInt16 flipped = flipUInt16(nonNetworkOrder);
	[self appendBytes:&flipped length:2];
}

- (void)appendNetworkOrderUInt32:(UInt32)nonNetworkOrder {
	UInt32 flipped = flipUInt32(nonNetworkOrder);
	[self appendBytes:&flipped length:4];
}

- (void)appendString:(NSString *)string paddToLen:(int)len {
	NSData * ascii = [string dataUsingEncoding:NSASCIIStringEncoding];
	if ([ascii length] > len) {
		[self appendBytes:[ascii bytes] length:len];
	} else {
		[self appendData:ascii];
		for (int i = 0; i < (len - [ascii length]); i++) {
			char zero = 0;
			[self appendBytes:&zero length:1];
		}
	}
}

@end
