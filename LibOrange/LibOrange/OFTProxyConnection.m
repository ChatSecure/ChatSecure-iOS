//
//  OFTProxyConnection.m
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OFTProxyConnection.h"


@implementation OFTProxyConnection

- (id)initWithFileDescriptor:(int)anOpenFd {
	if ((self = [super init])) {
		fileDescriptor = anOpenFd;
	}
	return self;
}
- (BOOL)writeCommand:(OFTProxyCommand *)cmd {
	return [cmd writeToFileDescriptor:fileDescriptor];
}
- (OFTProxyCommand *)readCommand {
	return [[[OFTProxyCommand alloc] initWithFileDescriptor:fileDescriptor] autorelease];
}

@end
