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

@property (nonatomic, retain) NSMutableDictionary *oscarBuddies;
@property (nonatomic, retain) NSMutableDictionary *xmppBuddies;

-(NSMutableDictionary*)allBuddies;
-(void)addBuddy:(OTRBuddy*)newBuddy;
-(void)removeOScarBuddies;
-(void)removeXmppBuddies;
-(NSUInteger)count;
-(OTRBuddy*)getBuddyByName:(NSString*)buddyName;

+(NSArray*)sortBuddies:(NSMutableDictionary*)buddies;

@end
