//
//  AIMBlistBuddy.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBuddyStatus.h"
#import "AIMBuddyIcon.h"

@class AIMBlistGroup;

@interface AIMBlistBuddy : NSObject {
    AIMBlistGroup * group;
	NSString * username;
	UInt16 feedbagItemID;
	AIMBuddyStatus * status;
	AIMBuddyIcon * buddyIcon;
}

@property (nonatomic, assign) AIMBlistGroup * group;
@property (readonly) NSString * username;
@property (readwrite) UInt16 feedbagItemID;
@property (nonatomic, retain) AIMBuddyStatus * status;
@property (nonatomic, retain) AIMBuddyIcon * buddyIcon;

- (id)initWithUsername:(NSString *)theUsername;
- (BOOL)usernameIsEqual:(NSString *)aUsername;

@end
