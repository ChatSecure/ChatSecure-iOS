//
//  AIMMessage.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMMessage.h"


@implementation AIMMessage

@synthesize buddy;
@synthesize message;
@synthesize isAutoresponse;

- (id)initWithICBMMessage:(AIMICBMMessageToClient *)theMessage fromBlist:(AIMBlist *)blist {
	if ((self = [super init])) {
		self.buddy = [blist buddyWithUsername:[[theMessage nickInfo] username]];
		self.message = [theMessage extractMessageContents];
		self.isAutoresponse = [theMessage isAutoResponse];
	}
	return self;
}

+ (AIMMessage *)messageWithBuddy:(AIMBlistBuddy *)_buddy message:(NSString *)_message {
	AIMMessage * message = [[AIMMessage alloc] init];
	message.message = _message;
	message.buddy = _buddy;
	message.isAutoresponse = NO;
	return [message autorelease];
}

+ (AIMMessage *)autoresponseMessageWithBuddy:(AIMBlistBuddy *)_buddy message:(NSString *)_message {
	AIMMessage * msg = [AIMMessage messageWithBuddy:_buddy message:_message];
	msg.isAutoresponse = YES;
	return msg;
}

- (NSString *)plainTextMessage {
	return [message stringByRemovingAOLRTFTags];
}

- (void)dealloc {
	self.buddy = nil;
	self.message = nil;
	[super dealloc];
}

@end
