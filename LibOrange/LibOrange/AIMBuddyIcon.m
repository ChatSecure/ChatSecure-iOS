//
//  AIMBuddyIcon.m
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBuddyIcon.h"


@implementation AIMBuddyIcon

@synthesize bartItem;
@synthesize iconData;

- (id)initWithBid:(AIMBArtID *)bid iconData:(NSData *)_iconData {
	if ((self = [super init])) {
		bartItem = [bid retain];
		iconData = [_iconData retain];
	}
	return self;
}
- (AIMBuddyIconFormat)iconDataFormat {
	/* TODO: parse icon data. */
	if ([iconData length] >= 3) {
		if (memcmp("GIF", [iconData bytes], 3) == 0) {
			return AIMBuddyIconGIFFormat;
		}
	} if ([iconData length] >= 2) {
		if (memcmp("BM", [iconData bytes], 2) == 0) {
			return AIMBuddyIconBMPFormat;
		}
	} if ([iconData length] >= 10) {
		if (memcmp("JFIF", &((const char *)[iconData bytes])[6], 4) == 0) {
			return AIMBuddyIconJPEGFormat;
		}
	}
	return AIMBuddyIconNoImageFormat;
}

- (NSString *)description {
	NSString * fmtStr = @"Unknown";
	AIMBuddyIconFormat fmt = [self iconDataFormat];
	switch (fmt) {
		case AIMBuddyIconBMPFormat:
			fmtStr = @"BMP";
			break;
		case AIMBuddyIconGIFFormat:
			fmtStr = @"GIF";
			break;
		case AIMBuddyIconJPEGFormat:
			fmtStr = @"JPEG";
			break;
		default:
			break;
	}
	return [NSString stringWithFormat:@"<AIMBuddyIcon fmt=%@ dataLength=%lu>", fmtStr, [iconData length]];
}

- (void)dealloc {
	[bartItem release];
	[iconData release];
	[super dealloc];
}

@end
