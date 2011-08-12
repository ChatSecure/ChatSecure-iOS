//
//  FeedbagOperation.h
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"
#import "AIMSession.h"

@protocol FeedbagTransaction <NSObject>

/**
 * Called when this feedbag operation will be performed.  This should generate
 * an internal array of snacs that should be sent in order to the server.  Once
 * the server okays the change, the SNAC will be applied, and the next one will
 * be sent.
 * @param feedbag The feedbag to which the operation will be applied.
 */
- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session;

/**
 * Called to check if the operations have been created.
 * @return YES if -createOperationsWithFeedbag:session: was called in the past,
 * NO otherwise.
 */
- (BOOL)hasCreatedOperations;

/**
 * @return the next SNAC required for the feedbag transaction.
 */
- (SNAC *)nextTransactionSNAC;

/**
 * @return the last SNAC that was returned by -nextTransactionSNAC.  This
 * can be nil if -nextTransactionSNAC was never called.
 */
- (SNAC *)currentTransactionSNAC;

@end
