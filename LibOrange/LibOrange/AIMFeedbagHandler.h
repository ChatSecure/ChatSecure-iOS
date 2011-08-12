//
//  AIMFeedbagHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMFeedbag+Search.h"
#import "AIMFeedbagRights.h"
#import "AIMTempBuddyHandler.h"

#import "FTCreateRootGroup.h"
#import "FTSetPDMode.h"
#import "AIMFeedbagStatus.h"
#import "FTAddGroup.h"
#import "Debug.h"


@class AIMFeedbagHandler;

@protocol AIMFeedbagHandlerDelegate <NSObject>

@optional
- (void)aimFeedbagHandlerGotBuddyList:(AIMFeedbagHandler *)feedbagHandler;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDeleted:(AIMBlistBuddy *)oldBuddy;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyAdded:(AIMBlistBuddy *)newBuddy;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupAdded:(AIMBlistGroup *)newGroup;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupDeleted:(AIMBlistGroup *)oldGroup;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupRenamed:(AIMBlistGroup *)theGroup;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDenied:(NSString *)username;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyPermitted:(NSString *)username;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUndenied:(NSString *)username;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUnpermitted:(NSString *)username;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender transactionFailed:(id<FeedbagTransaction>)transaction;

@end

@interface AIMFeedbagHandler : NSObject <AIMSessionHandler> {
    AIMSession * session;
	AIMFeedbag * feedbag;
	AIMFeedbagRights * feedbagRights;
	AIMTempBuddyHandler * tempBuddyHandler;
	id<AIMFeedbagHandlerDelegate> delegate;
	NSMutableArray * transactions;
}

@property (readonly) AIMFeedbag * feedbag;
@property (readonly) AIMSession * session;
@property (nonatomic, retain) AIMTempBuddyHandler * tempBuddyHandler;
@property (nonatomic, retain) AIMFeedbagRights * feedbagRights;
@property (nonatomic, assign) id<AIMFeedbagHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)theSession;
- (BOOL)sendFeedbagRequest;
- (void)pushTransaction:(id<FeedbagTransaction>)transaction;
- (UInt8)currentPDMode:(BOOL *)isPresent;

@end
