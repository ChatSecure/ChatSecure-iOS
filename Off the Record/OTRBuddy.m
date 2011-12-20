//
//  OTRBuddy.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRBuddy.h"

@implementation OTRBuddy

@synthesize name;
@synthesize protocol;
@synthesize groupName;
@synthesize status;

-(id)initWithName:(NSString*)buddyName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    self = [super init];
    
    if(self)
    {
        name = buddyName;
        protocol = buddyProtocol;
        status = buddyStatus;
        groupName = buddyGroupName;
    }
    return self;
}

+(OTRBuddy*)buddyWithName:(NSString*)buddyName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString *)buddyGroupName
{
    OTRBuddy *newBuddy = [[[OTRBuddy alloc] initWithName:buddyName protocol:buddyProtocol status:buddyStatus groupName:buddyGroupName] autorelease];
    return newBuddy;
}

@end
