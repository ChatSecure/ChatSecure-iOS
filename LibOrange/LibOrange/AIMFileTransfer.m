//
//  AIMFileTransfer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFileTransfer.h"


@implementation AIMFileTransfer

@synthesize cookie;
@synthesize buddy;
@synthesize wasCancelled;
@synthesize lastProposal;

- (void)setIsTransferring:(BOOL)_isTransferring {
	[stateLock lock];
	isTransferring = _isTransferring;
	[stateLock unlock];
}

- (BOOL)isTransferring {
	[stateLock lock];
	BOOL _isTransferring = isTransferring;
	[stateLock unlock];
	return _isTransferring;
}

- (void)setProgress:(float)_progress {
	[stateLock lock];
	progress = _progress;
	[stateLock unlock];
}

- (float)progress {
	[stateLock lock];
	float theState = progress;
	[stateLock unlock];
	return theState;
}

- (id)initWithCookie:(AIMICBMCookie *)theCookie {
	if ((self = [super init])) {
		cookie = [theCookie retain];
		stateLock = [[NSLock alloc] init];
	}
	return self;
}

- (NSString *)description {
	return [super description];
}

- (void)dealloc {
	[stateLock release];
	[cookie release];
	self.buddy = nil;
	self.lastProposal = nil;
	[super dealloc];
}

@end
