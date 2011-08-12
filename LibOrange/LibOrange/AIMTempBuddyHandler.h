//
//  AIMTempBuddyHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBlistBuddy.h"
#import "BasicStrings.h"

@class AIMSession;

@interface AIMTempBuddyHandler : NSObject {
    NSMutableArray * tempBuddies;
	AIMSession * session;
}

- (id)initWithSession:(AIMSession *)session;
- (void)sessionClosed;
- (NSArray *)temporaryBuddies;
- (AIMBlistBuddy *)addTempBuddy:(NSString *)screenName;
- (AIMBlistBuddy *)tempBuddyWithName:(NSString *)screenName;
- (void)deleteTempBuddy:(AIMBlistBuddy *)tempBuddy;

@end
