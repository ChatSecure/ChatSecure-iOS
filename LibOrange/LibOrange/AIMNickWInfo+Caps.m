//
//  AIMNickWInfo+Caps.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMNickWInfo+Caps.h"


@implementation AIMNickWInfo (Caps)

- (NSArray *)buddyCapabilities {
	TLV * capsArray = [self attributeOfType:TLV_CAPS];
	if (!capsArray) {
		return nil;
	} else {
		NSMutableArray * caps = [[NSMutableArray alloc] init];
		NSData * capData = [capsArray tlvData];
		
		for (int i = 0; i <= (int)[capData length] - 16; i += 16) {
			NSData * uuid = [NSData dataWithBytes:&((const char *)[capData bytes])[i] length:16];
			AIMCapability * cap = [[AIMCapability alloc] initWithUUID:uuid];
			[caps addObject:cap];
			[cap release];
		}
		
		NSArray * immutable = [NSArray arrayWithArray:caps];
		[caps release];
		return immutable;
	}
}

@end
