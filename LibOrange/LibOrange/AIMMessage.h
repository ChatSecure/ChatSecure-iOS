//
//  AIMMessage.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBlistBuddy.h"
#import "AIMBlist.h"
#import "AIMICBMMessageToClient.h"
#import "NSString+AOLRTF.h"

@interface AIMMessage : NSObject {
	AIMBlistBuddy * buddy;
	NSString * message;
	BOOL isAutoresponse;
}

@property (nonatomic, retain) AIMBlistBuddy * buddy;
@property (nonatomic, retain) NSString * message;
@property (readwrite) BOOL isAutoresponse;

- (id)initWithICBMMessage:(AIMICBMMessageToClient *)message fromBlist:(AIMBlist *)blist;
+ (AIMMessage *)messageWithBuddy:(AIMBlistBuddy *)_buddy message:(NSString *)_message;
+ (AIMMessage *)autoresponseMessageWithBuddy:(AIMBlistBuddy *)_buddy message:(NSString *)_message;

- (NSString *)plainTextMessage;

@end
