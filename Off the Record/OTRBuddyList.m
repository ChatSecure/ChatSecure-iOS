//
//  OTRBuddyList.m
//  Off the Record
//
//  Created by Chris Ballinger on 12/20/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyList.h"

@implementation OTRBuddyList

@synthesize allBuddies;
@synthesize activeConversations;

-(id)init
{
    if(self = [super init])
    {
        self.activeConversations = [[NSMutableSet alloc] init];
        self.allBuddies = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+(NSArray*)sortBuddies:(NSMutableDictionary*)buddies
{
    NSMutableArray * tempAllBuddies = [[NSMutableArray alloc] init];
    for(NSDictionary * tempBuddies in [buddies allValues])
    {
        [tempAllBuddies addObjectsFromArray:[tempBuddies allValues]];
    }
    
    NSSortDescriptor *buddyNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSSortDescriptor *statusDescriptor = [[NSSortDescriptor alloc] initWithKey:@"status"
                                                      ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:statusDescriptor, buddyNameDescriptor, nil];
    
    return [tempAllBuddies sortedArrayUsingDescriptors:sortDescriptors];
}

-(NSUInteger)count
{
    NSUInteger numberOfBuddies = 0;
    for (id key in self.allBuddies)
    {
        numberOfBuddies = numberOfBuddies + [[self.allBuddies objectForKey:key] count];
    }
    return numberOfBuddies;
}

-(void)removeAllBuddies
{
    [self.allBuddies removeAllObjects];
}

-(void)removeBuddiesforAccount:(OTRAccount *)account{
    [self.allBuddies removeObjectForKey:account.uniqueIdentifier];
}

-(void)addBuddy:(OTRBuddy*)newBuddy
{
    [[self.allBuddies objectForKey:newBuddy.protocol.account.uniqueIdentifier] setObject:newBuddy forKey:newBuddy.accountName];
}

-(void) updateBuddies:(NSArray *)arrayOfBuddies
{
    for (OTRBuddy * buddy in arrayOfBuddies)
    {
        if(![self.allBuddies objectForKey:buddy.protocol.account.uniqueIdentifier])
        {
            [self.allBuddies setObject:[NSMutableDictionary dictionaryWithCapacity:arrayOfBuddies.count] forKey:buddy.protocol.account.uniqueIdentifier];
        }
        OTRBuddy * existingBuddy = [[self.allBuddies objectForKey:buddy.protocol.account.uniqueIdentifier] objectForKey:buddy.accountName];
        if(!existingBuddy)
        {
            [[self.allBuddies objectForKey:buddy.protocol.account.uniqueIdentifier] setObject:buddy forKey:buddy.accountName];
        }
    }
}

-(OTRBuddy *)getbuddyForUserName:(NSString *)buddyUserName accountUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[allBuddies objectForKey:uniqueIdentifier] objectForKey:buddyUserName];
}

@end
