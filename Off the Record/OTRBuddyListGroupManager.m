//
//  OTRBuddyListGroupManager.m
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyListGroupManager.h"

#define kGroupNameKey @"groupNameKey"
#define kBuddyControllerKey @"groupControllerKey"

@implementation OTRBuddyListGroupManager

@synthesize onlineBuddyGroups,offlineBuddyGroups,delegate;
@synthesize groupFetchedResultsController = _groupFetchedResultsController;


-(id)initWithFetchedResultsDelegete:(id) newDelegate
{
    if(self = [self init])
    {
        self.onlineBuddyGroups = [NSMutableArray array];
        self.offlineBuddyGroups = [NSMutableArray array];
        [self groupFetchedResultsController];
        
        self.delegate = newDelegate;
    }
    return self;
}

-(void)loadAllControllers
{
    NSArray * groups = [OTRManagedGroup MR_findAll];
    
    for ( OTRManagedGroup * group in groups)
    {
        [self addOfflineBuddyController:[self buddyFetchedResultsControllerWithManagedGroup:group] groupName:group.name];
    }
}

-(void)updateGroups
{
    
    
}

-(NSUInteger)numberOfBuddiesAtIndex:(NSUInteger)index
{
    NSFetchedResultsController * controller = [self resultsControllerAtIndex:index];
    return [[controller fetchedObjects] count];
    
}
-(NSUInteger)numberOfGroups
{
    return [self.onlineBuddyGroups count];
}

-(NSString *)groupNameAtIndex:(NSUInteger)index
{
    return [[self.onlineBuddyGroups objectAtIndex:index] objectForKey:kGroupNameKey];
}

-(OTRManagedBuddy *)buddyAtIndexPath:(NSIndexPath *)indexPath
{
     NSFetchedResultsController * controller = [self resultsControllerAtIndex: indexPath.section];
    return [controller objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row inSection:0]];
}

-(void)addOfflineBuddyController:(NSFetchedResultsController *)controller groupName:(NSString *)groupName
{
    [self.offlineBuddyGroups addObject:@{kGroupNameKey: groupName,kBuddyControllerKey:controller}];
    
    
}

-(NSInteger)addOnlineBuddyController:(NSFetchedResultsController *)controller groupName:(NSString *)groupName
{
    NSDictionary * controllerDictionary = @{kGroupNameKey: groupName,kBuddyControllerKey:controller};
    [self.onlineBuddyGroups addObject:controllerDictionary];
    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kGroupNameKey ascending:YES];
    [self.onlineBuddyGroups sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    return  [self.onlineBuddyGroups indexOfObject:controllerDictionary];
}
-(NSFetchedResultsController *)resultsControllerAtIndex:(NSInteger)index
{
    return [[self.onlineBuddyGroups objectAtIndex:index] objectForKey:kBuddyControllerKey];
}

-(NSFetchedResultsController *)buddyFetchedResultsControllerWithManagedGroup:(OTRManagedGroup *)managedGroup
{
    NSLog(@"Fetched: %@",managedGroup.name);
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"accountName != nil OR displayName != nil"];
    NSPredicate * onlineFilter = [NSPredicate predicateWithFormat:@"%K != %d",OTRManagedBuddyAttributes.currentStatus,kOTRBuddyStatusOffline];
    NSPredicate * groupFilter = [NSPredicate predicateWithFormat:@"%@ IN %K",managedGroup,OTRManagedBuddyRelationships.groups];
    NSPredicate * compoundFilter = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,groupFilter,onlineFilter]];
    
    NSFetchedResultsController * buddyFetchController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:compoundFilter sortedBy:@"currentStatus,displayName" ascending:YES delegate:self];
    return buddyFetchController;
}

-(NSString *)groupNameWithController:(NSFetchedResultsController *)controller
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@",kBuddyControllerKey,controller];
    NSArray * filteredArray = [self.onlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count]) {
        return [[filteredArray lastObject] objectForKey:kGroupNameKey];
    }
    
    filteredArray = [self.offlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count])
    {
        return [[filteredArray lastObject] objectForKey:kGroupNameKey];
    }
    
    return @"";
    
}

-(NSInteger)offlineIndexWithController:(NSFetchedResultsController *)controller
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@",kBuddyControllerKey,controller];
    NSArray * filteredArray = [self.offlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count]) {
        return [self.offlineBuddyGroups indexOfObject:[filteredArray lastObject]];
    }
    return -1;
    
}
-(NSInteger)onlineIndexWithController:(NSFetchedResultsController *)controller
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@",kBuddyControllerKey,controller];
    NSArray * filteredArray = [self.onlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count]) {
        return [self.onlineBuddyGroups indexOfObject:[filteredArray lastObject]];
    }
    return -1;
}
-(void)controllerWentOffline:(NSFetchedResultsController *)controller
{
    NSString * groupName = [self groupNameWithController:controller];
    NSInteger index = [self onlineIndexWithController:controller];
    if (index > 0) {
        [self.onlineBuddyGroups removeObjectAtIndex:index];

    }
    [self addOfflineBuddyController:controller groupName:groupName];
    [self.delegate manager:self didChangeSectionAtIndex:index newSectionIndex:0 forChangeType:NSFetchedResultsChangeDelete];

    
    //delegate call
    
}
-(void)controllerWentOnline:(NSFetchedResultsController *)controller
{
    NSString * groupName = [self groupNameWithController:controller];
    NSInteger index =  [self offlineIndexWithController:controller];
    if (index>0) {
        [self.offlineBuddyGroups removeObjectAtIndex:index];

    }
    index = [self addOnlineBuddyController:controller groupName:groupName];
    [self.delegate manager:self didChangeSectionAtIndex:0 newSectionIndex:index forChangeType:NSFetchedResultsChangeInsert];
}


-(BOOL)isControllerOffline:(NSFetchedResultsController *)controller
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@",kBuddyControllerKey,controller];
    NSArray * filteredArray = [self.offlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count]) {
        return YES;
    }
    return NO;
}
-(NSFetchedResultsController *)groupFetchedResultsController
{
    if (_groupFetchedResultsController) {
        return _groupFetchedResultsController;
    }
    
    _groupFetchedResultsController = [OTRManagedGroup MR_fetchAllGroupedBy:nil withPredicate:nil sortedBy:nil ascending:YES delegate:self];
    return _groupFetchedResultsController;
}

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [delegate controllerWillChangeContent:controller];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if ([controller isEqual:_groupFetchedResultsController]) {
        if (type == NSFetchedResultsChangeInsert) {
            [self addOfflineBuddyController:[self buddyFetchedResultsControllerWithManagedGroup:((OTRManagedGroup *)anObject)] groupName:((OTRManagedGroup *)anObject).name];
        }
        return;
    }
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            if ([self isControllerOffline:controller]) {
                [self controllerWentOnline:controller];
            }
        }
            break;
        case NSFetchedResultsChangeDelete:
        {
            if (![self isControllerOffline:controller] && [[controller fetchedObjects] count] == 1) {
                [self controllerWentOffline:controller];
            }
            
        }
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            break;
    }
    
    if (![self isControllerOffline:controller]) {
        [self.delegate controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
    
    
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [delegate controllerDidChangeContent:controller];
}


@end
