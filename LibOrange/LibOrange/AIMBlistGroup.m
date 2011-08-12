//
//  AIMBlistGroup.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBlistGroup.h"


@implementation AIMBlistGroup

@synthesize feedbagGroupID;
@synthesize name;

- (id)initWithBuddies:(NSArray *)theBuddies name:(NSString *)groupName {
	if ((self = [super init])) {
		buddies = [[NSMutableArray alloc] initWithArray:theBuddies];
		self.name = groupName;
	}
	return self;
}
- (AIMBlistBuddy *)buddyWithUsername:(NSString *)screenName {
	for (AIMBlistBuddy * buddy in buddies) {
		if ([buddy usernameIsEqual:screenName]) {
			return buddy;
		}
	}
	return nil;
}
- (NSArray *)buddies {
	return buddies;
}
- (NSString *)name {
	return name;
}

- (NSString *)description {
	NSMutableString * string = [NSMutableString stringWithFormat:@"Group \"%@\": (\n", name];
	for (AIMBlistBuddy * buddy in buddies) {
		[string appendFormat:@"  %@\n", [buddy description]];
	}
	[string appendFormat:@")\n"];
	return string;
}

- (void)dealloc {
	[buddies release];
	self.name = nil;
	[super dealloc];
}

@end
