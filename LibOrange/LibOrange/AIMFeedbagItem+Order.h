//
//  AIMFeedbagItem+Order.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbagItem.h"

@interface AIMFeedbagItem (Order)

/**
 * @return An array of NSNumbers which hold IDs for items in the order
 * attribute's data.
 */
- (NSArray *)groupOrder;

/**
 * Gets the change in order between two feedbag items.
 * @param newItem The item to which the gauged modifications were made.
 * @param added All of the order items that were added to newItem are put here.
 * @param added All of the order items that were removed from us are put here.
 * @return YES if something was added or removed, NO if no modifications occured.
 */
- (BOOL)orderChangeToItem:(AIMFeedbagItem *)newItem added:(NSArray **)added removed:(NSArray **)removed;

/**
 * Returns a new ORDER TLV containing an additional item ID.
 * @param theID The item ID to add.
 * @return A generated ORDER attribute.
 */
- (TLV *)orderByAddingID:(UInt16)theID;

/**
 * Returns a new ORDER TLV which doesn't have a specified item ID.
 * @param theID The item ID to remove.
 * @return A generated ORDER attribute.
 */
- (TLV *)orderByRemovingID:(UInt16)theID;

/**
 * Creates a duplicate item, containing an updated order item.
 * @param newItem The item to add to the ORDER attribute.
 * @return An autorelease'd item that should be used in a FEEDBAG__UPDATE.
 */
- (AIMFeedbagItem *)itemByAddingOrderItem:(UInt16)newItem;

/**
 * Creates a duplicate item, containing an updated order item.
 * @param newItem The item to remove from the ORDER attribute.
 * @return An autorelease'd item that should be used in a FEEDBAG__UPDATE.
 */
- (AIMFeedbagItem *)itemByRemovingOrderItem:(UInt16)newItem;

@end
