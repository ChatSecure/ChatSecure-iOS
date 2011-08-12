//
//  AIMLoginHostInfo.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMLoginHostInfo.h"


@implementation AIMLoginHostInfo

@synthesize hostName;
@synthesize port;
@synthesize cookie;

- (id)initWithHost:(NSString *)theHost port:(UInt16)thePort cookie:(NSData *)theCookie {
	if ((self = [super init])) {
		self.hostName = theHost;
		self.port = thePort;
		self.cookie = theCookie;
	}
	return self;
}

- (void)dealloc {
	self.hostName = nil;
	self.cookie = nil;
	[super dealloc];
}

@end
