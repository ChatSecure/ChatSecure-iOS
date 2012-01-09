//
//  OTRBuddy.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
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
        name = [buddyName retain];
        protocol = [buddyProtocol retain];
        status = buddyStatus;
        groupName = [buddyGroupName retain];
    }
    return self;
}

+(OTRBuddy*)buddyWithName:(NSString*)buddyName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString *)buddyGroupName
{
    OTRBuddy *newBuddy = [[[OTRBuddy alloc] initWithName:buddyName protocol:buddyProtocol status:buddyStatus groupName:buddyGroupName] autorelease];
    return newBuddy;
}

-(void)dealloc
{
    [name release];
    [protocol release];
    [groupName release];
    [super dealloc];
}

@end
