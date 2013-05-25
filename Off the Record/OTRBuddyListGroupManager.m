//
//  OTRBuddyListGroupManager.m
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyListGroupManager.h"
#import "OTRManagedAccount.h"

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
    if (controller && [groupName length]) {
        [self.offlineBuddyGroups addObject:@{kGroupNameKey: groupName,kBuddyControllerKey:controller}];
    }
    
    
    
}

-(NSInteger)addOnlineBuddyController:(NSFetchedResultsController *)controller groupName:(NSString *)groupName
{
    NSDictionary * controllerDictionary = @{kGroupNameKey: groupName,kBuddyControllerKey:controller};
    [self.onlineBuddyGroups addObject:controllerDictionary];
    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kGroupNameKey ascending:YES];
    [self.onlineBuddyGroups sortUsingDescriptors:@[sortDescriptor]];
    
    return  [self.onlineBuddyGroups indexOfObject:controllerDictionary];
}
-(NSFetchedResultsController *)resultsControllerAtIndex:(NSInteger)index
{
    return [[self.onlineBuddyGroups objectAtIndex:index] objectForKey:kBuddyControllerKey];
}

-(NSFetchedResultsController *)buddyFetchedResultsControllerWithManagedGroup:(OTRManagedGroup *)managedGroup
{
    NSLog(@"Fetched: %@",managedGroup.name);
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"%@ != nil OR %@ != nil",OTRManagedBuddyAttributes.accountName,OTRManagedBuddyAttributes.displayName];
    NSPredicate * onlineFilter = [NSPredicate predicateWithFormat:@"%K != %d",OTRManagedBuddyAttributes.currentStatus,kOTRBuddyStatusOffline];
    NSPredicate * groupFilter = [NSPredicate predicateWithFormat:@"%@ IN %K",managedGroup,OTRManagedBuddyRelationships.groups];
    NSPredicate * selfBuddyFilter = [NSPredicate predicateWithFormat:@"accountName != account.username"];
    NSPredicate * compoundFilter = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,groupFilter,onlineFilter,selfBuddyFilter]];

    
    NSString * sortByStirng = [NSString stringWithFormat:@"%@,%@,%@",OTRManagedBuddyAttributes.currentStatus,OTRManagedBuddyAttributes.displayName,OTRManagedBuddyAttributes.accountName];
    
    NSFetchedResultsController * buddyFetchController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:compoundFilter sortedBy:sortByStirng ascending:YES delegate:self];
    [buddyFetchController.fetchRequest setShouldRefreshRefetchedObjects:YES];
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
    if (index > -1) {
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
    if (index>-1) {
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
-(BOOL)isControllerOnline:(NSFetchedResultsController *)controller
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@",kBuddyControllerKey,controller];
    NSArray * filteredArray = [self.onlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count]) {
        return YES;
    }
    return NO;
}

-(NSFetchedResultsController *)controllerWithBuddyGroupName:(NSString *)groupName
{
    NSFetchedResultsController * controller = nil;
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@",kGroupNameKey,groupName];
    NSArray * filteredArray = [self.onlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count]) {
        controller = [[filteredArray lastObject] objectForKey:kBuddyControllerKey];
    }
    
    filteredArray = [self.offlineBuddyGroups filteredArrayUsingPredicate:filter];
    if ([filteredArray count]) {
        controller =[[filteredArray lastObject] objectForKey:kBuddyControllerKey];
    }
    
    return controller;
    
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
    if (![self isControllerOffline:controller]) {
        [delegate controllerWillChangeContent:controller];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if ([controller isEqual:_groupFetchedResultsController]) {
        if (type == NSFetchedResultsChangeInsert) {
            OTRManagedGroup * managedGroup = (OTRManagedGroup *)anObject;
            if(![self controllerWithBuddyGroupName:managedGroup.name])
            {
                [self addOfflineBuddyController:[self buddyFetchedResultsControllerWithManagedGroup:managedGroup] groupName:managedGroup.name];
            }
        }
        return;
    }
    
    if (![self isControllerOffline:controller]) {
        NSInteger section = [self onlineIndexWithController:controller];
        
        if (indexPath) {
            indexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:section];
        }
        
        if (newIndexPath) {
            newIndexPath = [NSIndexPath indexPathForItem:newIndexPath.row inSection:section];
        }
        
        
        [self.delegate controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
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
            if (![self isControllerOffline:controller] && [[controller fetchedObjects] count] == 0) {
                [self controllerWentOffline:controller];
            }
            
        }
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            break;
    }
    
    
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (![self isControllerOffline:controller]) {
        [delegate controllerDidChangeContent:controller];
    }
}

@end
