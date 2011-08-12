//
//  AIMBlistGroup.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBlistBuddy.h"

@interface AIMBlistGroup : NSObject {
    NSMutableArray * buddies;
	NSString * name;
	UInt16 feedbagGroupID;
}

@property (readwrite) UInt16 feedbagGroupID;
@property (nonatomic, retain) NSString * name;

- (id)initWithBuddies:(NSArray *)theBuddies name:(NSString *)groupName;
- (AIMBlistBuddy *)buddyWithUsername:(NSString *)screenName;
- (NSArray *)buddies;
- (NSString *)name;

@end
