//
//  JKExpandTableView.h
//  ExpandTableView
//
//  Created by Jack Kwok on 7/5/13.
//  Copyright (c) 2013 Jack Kwok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JKMultiSelectSubTableViewCell.h"

/*!
 @protocol JKExpandTableViewDelegate
 @discussion Users of this class must implement this protocol.
 */
@protocol JKExpandTableViewDelegate <NSObject>
@required

/*! Within a single JKExpandTableView, it is permissible to have a mix of multi-selectables and non-multi-selectables.
 
 @param parentIndex The parent index in question
 @return YES if more than one child under this parent can be selected at the same time.  Otherwise, return NO.
 */
- (BOOL) shouldSupportMultipleSelectableChildrenAtParentIndex:(NSInteger) parentIndex;

@optional
/*! Optional method the delegate should implement to get notified when a child is clicked on.

 @param childIndex The child index in question
 @param parentIndex The parent index in question
 */
- (void) tableView:(UITableView *)tableView didSelectCellAtChildIndex:(NSInteger) childIndex withInParentCellIndex:(NSInteger) parentIndex;
/*! Optional method the delegate should implement to get notified when a child is clicked on.
 
 @param childIndex The child index in question
 @param parentIndex The parent index in question
 */
- (void) tableView:(UITableView *)tableView didDeselectCellAtChildIndex:(NSInteger) childIndex withInParentCellIndex:(NSInteger) parentIndex;
/*! Optional method to get notified when a parent is clicked on.
 
  @param parentIndex The parent index in question
 */
- (void) tableView:(UITableView *)tableView didSelectParentCellAtIndex:(NSInteger) parentIndex;

/*! Optional method to set custom foreground color.
 
 @return UIColor 
 */
- (UIColor *) foregroundColor;
/*! Optional method to set custom foreground color.
 
 @return UIColor
 */
- (UIColor *) backgroundColor;
/*! Optional method to set a custom selection indicator icon.
 
 @return UIImage
 */
- (UIImage *) selectionIndicatorIcon;
/*! Optional method to set custom font for the labels on the Parent cells.

 @return UIFont for the label on the parent cells
 */
- (UIFont *) fontForParents;
/*! Optional method to set custom Font for the labels on the Children cells.
 
 @return UIFont for the label on the children cells
 */
- (UIFont *) fontForChildren;
@end

/*!
 @protocol JKExpandTableViewDataSource
 @discussion Users of this class must implement this protocol.
 */
@protocol JKExpandTableViewDataSource <NSObject>
@required
/*!
 
 @return The total number of parent cells in this table.
 */
- (NSInteger) numberOfParentCells;
/*!
 @param parentIndex The parent index in question
 @return The total number of children cells under each parent in this table.
 */
- (NSInteger) numberOfChildCellsUnderParentIndex:(NSInteger) parentIndex;
/*!
 @param parentIndex The parent index in question
 @return The label string shown on the parent cell.
 */
- (NSString *) labelForParentCellAtIndex:(NSInteger) parentIndex;

/*!
 @param childIndex The child index in question
 @param parentIndex The parent index in question
 @return The label string shown on the child cell.
 */
- (NSString *) labelForCellAtChildIndex:(NSInteger) childIndex withinParentCellIndex:(NSInteger) parentIndex;

/*!
 @param childIndex The child index in question
 @param parentIndex The parent index in question
 @return YES if the child is selected.  Otherwise, NO.
 */
- (BOOL) shouldDisplaySelectedStateForCellAtChildIndex:(NSInteger) childIndex withinParentCellIndex:(NSInteger) parentIndex;

@optional

/*! Optional method
 
 @param parentIndex The parent index in question
 @return UIImage shown to the left of the label for the parent.
 */
- (UIImage *) iconForParentCellAtIndex:(NSInteger) parentIndex;

/*! Optional method
 
 @param childIndex The child index in question
 @param parentIndex The parent index in question
 @return UIImage shown to the left of the label for the child.
 */
- (UIImage *) iconForCellAtChildIndex:(NSInteger) childIndex withinParentCellIndex:(NSInteger) parentIndex;

/*! Optional method
 
 @return YES if the parent icon should be rotated 90 degrees when parent is toggled.  Otherwise, return NO.
 */
- (BOOL) shouldRotateIconForParentOnToggle;
@end

@interface JKExpandTableView : UITableView
    <UITableViewDataSource, UITableViewDelegate, JKSubTableViewCellDelegate> {
    __weak id tableViewDelegate;
    __weak id dataSourceDelegate;
    NSMutableArray * expansionStates;
}

@property(nonatomic,weak) id<JKExpandTableViewDelegate> tableViewDelegate;
@property(nonatomic,weak,getter = getDataSourceDelegate, setter = setDataSourceDelegate:) id<JKExpandTableViewDataSource> dataSourceDelegate;
@property(nonatomic,strong) NSMutableArray * expansionStates;

@end
