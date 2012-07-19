//
//  OTRBuddyList.h
//  Off the Record
//
//  Created by Chris Ballinger on 12/20/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRBuddy.h"

@interface OTRBuddyList : NSObject

@property (nonatomic, retain) NSMutableDictionary *allBuddies;
@property (nonatomic, retain) NSMutableSet *activeConversations;


-(void)addBuddy:(OTRBuddy*)newBuddy;
-(void)removeBuddiesforAccount:(OTRAccount *)account;
-(NSUInteger)count;
-(OTRBuddy*)getbuddyForUserName:(NSString *)buddyUserName accountUniqueIdentifier:(NSString *)uniqueIdentifier;
-(void) updateBuddies:(NSArray *)arrayOfBuddies;

+(NSArray*)sortBuddies:(NSMutableDictionary*)buddies;

@end
