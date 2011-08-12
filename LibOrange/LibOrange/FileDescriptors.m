//
//  FileDescriptors.m
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileDescriptors.h"


BOOL fdRead (int fd, char * buffer, int len) {
	int hasRead = 0;
	while (hasRead < len) {
		int justGot = (int)read(fd, &buffer[hasRead], len - hasRead);
		if (justGot <= 0) return NO;
		hasRead += justGot;
	}
	return YES;
}

BOOL fdReadUInt16 (int fd, UInt16 * integ) {
	UInt16 buffer = 0;
	if (fdRead(fd, (char *)&buffer, 2) == NO) return NO;
	else {
		*integ = flipUInt16(buffer);
		return YES;
	}
}

BOOL fdReadUInt32 (int fd, UInt32 * integ) {
	UInt32 buffer = 0;
	if (fdRead(fd, (char *)&buffer, 4) == NO) return NO;
	else {
		*integ = flipUInt32(buffer);
		return YES;
	}
}
