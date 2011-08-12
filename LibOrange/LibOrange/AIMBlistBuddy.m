//
//  AIMBlistBuddy.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBlistBuddy.h"
#import "AIMBlistGroup.h"


@implementation AIMBlistBuddy

@synthesize group;
@synthesize username;
@synthesize feedbagItemID;
@synthesize status;
@synthesize buddyIcon;

- (id)initWithUsername:(NSString *)theUsername {
	if ((self = [super init])) {
		username = [theUsername retain];
	}
	return self;
}

- (BOOL)usernameIsEqual:(NSString *)aUsername {
	// compress our username
	NSString * compressed = [username stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSString * anotherCompressed = [aUsername stringByReplacingOccurrencesOfString:@" " withString:@""];
	if ([[compressed lowercaseString] isEqual:[anotherCompressed lowercaseString]]) {
		return YES;
	} else return NO;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@", username];
}

- (void)dealloc {
	self.status = nil;
	self.buddyIcon = nil;
	[username release];
	[super dealloc];
}

@end
