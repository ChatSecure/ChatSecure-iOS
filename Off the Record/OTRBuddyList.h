//
//  OTRBuddyList.h
//  Off the Record
//
//  Created by Chris Ballinger on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRBuddy.h"

@interface OTRBuddyList : NSObject

@property (nonatomic, retain) NSMutableDictionary *oscarBuddies;
@property (nonatomic, retain) NSMutableDictionary *xmppBuddies;

-(NSMutableDictionary*)allBuddies;
-(void)addBuddy:(OTRBuddy*)newBuddy;
-(NSUInteger)count;

+(NSArray*)sortBuddies:(NSMutableDictionary*)buddies;

@end
