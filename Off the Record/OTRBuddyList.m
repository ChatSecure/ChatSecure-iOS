//
//  OTRBuddyList.m
//  Off the Record
//
//  Created by Chris Ballinger on 12/20/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

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

-(void)removeBuddiesforAccount:(OTRManagedAccount *)account{
    [self.allBuddies removeObjectForKey:account.uniqueIdentifier];
}

-(void)addBuddy:(OTRManagedBuddy*)newBuddy
{
    [[self.allBuddies objectForKey:newBuddy.account.uniqueIdentifier] setObject:newBuddy forKey:newBuddy.accountName];
}

-(void) updateBuddies:(NSArray *)arrayOfBuddies
{
    for (OTRManagedBuddy * buddy in arrayOfBuddies)
    {
        if(![self.allBuddies objectForKey:buddy.account.uniqueIdentifier])
        {
            [self.allBuddies setObject:[NSMutableDictionary dictionaryWithCapacity:arrayOfBuddies.count] forKey:buddy.account.uniqueIdentifier];
        }
        OTRManagedBuddy * existingBuddy = [[self.allBuddies objectForKey:buddy.account.uniqueIdentifier] objectForKey:buddy.accountName];
        if(!existingBuddy)
        {
            [[self.allBuddies objectForKey:buddy.account.uniqueIdentifier] setObject:buddy forKey:buddy.accountName];
        }
    }
}

-(OTRManagedBuddy *)getBuddyForUserName:(NSString *)buddyUserName accountUniqueIdentifier:(NSString *)uniqueIdentifier
{
    return [[allBuddies objectForKey:uniqueIdentifier] objectForKey:buddyUserName];
}

@end
