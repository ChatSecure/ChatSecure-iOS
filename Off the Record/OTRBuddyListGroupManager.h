//
//  OTRBuddyListGroupManager.h
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRManagedGroup.h"
#import "OTRManagedBuddy.h"

@class OTRBuddyListGroupManager;

@protocol OTRBuddyListGroupManagerDelegate <NSObject>
-(void)manager:(OTRBuddyListGroupManager *)manager didChangeSectionAtIndex:(NSUInteger)section newSectionIndex:(NSUInteger)newSecion forChangeType:(NSFetchedResultsChangeType)type;

@end


@interface OTRBuddyListGroupManager : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSMutableArray * buddyFetchedResultsControllerArray;
@property (nonatomic, strong) NSFetchedResultsController * groupFetchedResultsController;
@property (nonatomic, weak) id <NSFetchedResultsControllerDelegate, OTRBuddyListGroupManagerDelegate> delegate;


-(id)initWithFetchedResultsDelegete:(id) delegate;

-(NSUInteger)numberOfGroups;
-(NSUInteger)numberOfBuddiesAtIndex:(NSUInteger)index;
-(NSString *)groupNameAtIndex:(NSUInteger)index;
-(OTRManagedBuddy *)buddyAtIndexPath:(NSIndexPath *)indexPath;

-(void)addGroup:(OTRManagedGroup *)managedGroup atIndex:(NSUInteger) index;
-(void)removeGroupAtIndex:(NSUInteger)index;
-(void)updateGroup:(OTRManagedGroup *)managedGroup atIndex:(NSUInteger) index;
-(void)moveGroupfromIndex:(NSUInteger)index toIndex:(NSUInteger)newIndex;

@end


