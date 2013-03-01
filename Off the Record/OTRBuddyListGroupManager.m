//
//  OTRBuddyListGroupManager.m
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyListGroupManager.h"

@implementation OTRBuddyListGroupManager

@synthesize buddyFetchedResultsControllerArray,delegate;


-(id)initWithFetchedResultsDelegete:(id) newDelegate
{
    if(self = [self init])
    {
        self.buddyFetchedResultsControllerArray = [NSMutableArray array];
        self.delegate = newDelegate;
    }
    return self;
}

-(NSUInteger)numberOfBuddiesAtIndex:(NSUInteger)index
{
    NSFetchedResultsController * controller = [self resultsControllerAtIndex:index];
    return [[controller sections][0] numberOfObjects];
    
}
-(NSUInteger)numberOfGroups
{
    return [[self.groupFetchedResultsController sections][0] numberOfObjects];
}

-(NSString *)groupNameAtIndex:(NSUInteger)index
{
    OTRManagedGroup * managedGroup = [self.groupFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return managedGroup.name;
}

-(OTRManagedBuddy *)buddyAtIndexPath:(NSIndexPath *)indexPath
{
     NSFetchedResultsController * controller = [self resultsControllerAtIndex:indexPath.section];
    return [controller objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:0]];
}

-(void)addGroup:(OTRManagedGroup *)managedGroup atIndex:(NSUInteger) index
{
    NSLog(@"Fetched: %@",managedGroup.name);
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"accountName != nil OR displayName != nil"];
    NSPredicate * onlineFilter = [NSPredicate predicateWithFormat:@"%K != %d",OTRManagedBuddyAttributes.currentStatus,kOTRBuddyStatusOffline];
    NSPredicate * groupFilter = [NSPredicate predicateWithFormat:@"%@ IN %K",managedGroup,OTRManagedBuddyRelationships.groups];
    NSPredicate * compoundFilter = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,groupFilter,onlineFilter]];
    
    NSFetchedResultsController * buddyFetchController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:compoundFilter sortedBy:@"currentStatus,displayName" ascending:YES delegate:self.delegate];
    [buddyFetchedResultsControllerArray insertObject:buddyFetchController atIndex:index];
}
-(void)removeGroupAtIndex:(NSUInteger)index
{
    [self.buddyFetchedResultsControllerArray removeObjectAtIndex:index];
}

-(NSFetchedResultsController *)resultsControllerAtIndex:(NSUInteger) index
{
    return [self.buddyFetchedResultsControllerArray objectAtIndex:index];
}


-(void)updateGroup:(OTRManagedGroup *)managedGroup atIndex:(NSUInteger) index
{
    NSFetchedResultsController * controller = [self resultsControllerAtIndex:index];
    NSFetchRequest * searchRequest = [controller fetchRequest];
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"accountName != nil OR displayName != nil"];
    NSPredicate * onlineFilter = [NSPredicate predicateWithFormat:@"%K != %d",OTRManagedBuddyAttributes.currentStatus,kOTRBuddyStatusOffline];
    NSPredicate * groupFilter = [NSPredicate predicateWithFormat:@"%@ IN %K",managedGroup,OTRManagedBuddyRelationships.groups];
    NSPredicate * compoundFilter = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,groupFilter,onlineFilter]];
    
    [searchRequest setPredicate:compoundFilter];
    
    NSError *error = nil;
    if (![controller performFetch:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}
-(void)moveGroupfromIndex:(NSUInteger)from toIndex:(NSUInteger)to
{
    if (to != from) {
        id obj = [self.buddyFetchedResultsControllerArray objectAtIndex:from];
        [self.buddyFetchedResultsControllerArray removeObjectAtIndex:from];
        if (to >= [self.buddyFetchedResultsControllerArray count]) {
            [self.buddyFetchedResultsControllerArray addObject:obj];
        } else {
            [self.buddyFetchedResultsControllerArray insertObject:obj atIndex:to];
        }
    }
}

-(NSFetchedResultsController *)groupFetchedResultsController
{
    if(_groupFetchedResultsController)
    {
        return _groupFetchedResultsController;
    }
    
    //NSPredicate * hasBuddiesFilter = [NSPredicate predicateWithFormat:@"%K.@count != 0",OTRManagedGroupRelationships.buddies];
    NSPredicate * onlineBuddiesFilter = [NSPredicate predicateWithFormat:@"ANY %K.%K != %d",OTRManagedGroupRelationships.buddies,OTRManagedBuddyAttributes.currentStatus,kOTRBuddyStatusOffline];
    //NSPredicate * buddyFilter = [NSCompoundPredicate andPredicateWithSubpredicates:@[hasBuddiesFilter, onlineBuddiesFilter]];
    
    _groupFetchedResultsController = [OTRManagedGroup MR_fetchAllGroupedBy:nil withPredicate:onlineBuddiesFilter sortedBy:OTRManagedGroupAttributes.name ascending:YES delegate:self];
    
    return _groupFetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            OTRManagedGroup * group = [controller objectAtIndexPath:newIndexPath];
            [self addGroup:group atIndex:newIndexPath.row];
        }
            break;
        case NSFetchedResultsChangeDelete:
            [self removeGroupAtIndex:indexPath.row];
            break;
        case NSFetchedResultsChangeUpdate:
        {
            OTRManagedGroup * group = [controller objectAtIndexPath:indexPath];
            [self updateGroup:group atIndex:indexPath.row];
        }
            break;
        case NSFetchedResultsChangeMove:
            [self moveGroupfromIndex:indexPath.row toIndex:newIndexPath.row];
            break;
    }
    [self.delegate manager:self didChangeSectionAtIndex:indexPath.row newSectionIndex:newIndexPath.row forChangeType:type];
}


@end
