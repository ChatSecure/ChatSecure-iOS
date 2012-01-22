//
//  OTRBuddy.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/12/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"

@implementation OTRBuddy

@synthesize accountName;
@synthesize displayName;
@synthesize protocol;
@synthesize groupName;
@synthesize status;

-(id)initWithDisplayName:(NSString*)buddyName accountName:(NSString*) buddyAccountName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    self = [super init];
    
    if(self)
    {
        displayName = [buddyName retain];
        accountName = [buddyAccountName retain];
        protocol = [buddyProtocol retain];
        status = buddyStatus;
        groupName = [buddyGroupName retain];
    }
    return self;
}

+(OTRBuddy*)buddyWithDisplayName:(NSString*)buddyName accountName:(NSString*) accountName protocol:(NSString*)buddyProtocol status:(OTRBuddyStatus)buddyStatus groupName:(NSString*)buddyGroupName
{
    OTRBuddy *newBuddy = [[[OTRBuddy alloc] initWithDisplayName:buddyName accountName:accountName protocol:buddyProtocol status:buddyStatus groupName:buddyGroupName] autorelease];
    return newBuddy;
}

-(void)dealloc
{
    [accountName release];
    [displayName release];
    [protocol release];
    [groupName release];
    [super dealloc];
}

@end
