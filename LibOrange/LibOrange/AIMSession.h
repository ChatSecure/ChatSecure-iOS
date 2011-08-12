//
//  AIMSession.h
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARConnection.h"
#import "SNAC.h"
#import "AIMBlist.h"
#import "Debug.h"

@class AIMSession;

@protocol AIMSessionHandler

- (void)handleIncomingSnac:(SNAC *)aSnac;
- (void)sessionClosed;

@end

@protocol AIMSessionDelegate

- (void)aimSessionClosed:(AIMSession *)session;

@end

@interface AIMSession : NSObject <OSCARConnectionDelegate> {
    OSCARConnection * connection;
	NSThread * mainThread;
	NSThread * backgroundThread;
	NSMutableArray * handlers;
	NSObject<AIMSessionDelegate> * sessionDelegate;
	NSString * username;
	
	AIMBlist * buddyList;
	NSLock * reqIDLock;
	UInt32 reqID;
}

@property (readonly) OSCARConnection * connection;
@property (nonatomic, assign) NSThread * mainThread;
@property (nonatomic, retain) NSThread * backgroundThread;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, assign) NSObject<AIMSessionDelegate> * sessionDelegate;
@property (nonatomic, retain) AIMBlist * buddyList;

- (id)initWithConnection:(OSCARConnection *)theConnection;
- (void)addHandler:(id<AIMSessionHandler>)aHandler;
- (void)removeHandler:(id<AIMSessionHandler>)theHandler;
- (void)closeConnection;

- (UInt32)generateReqID;
- (BOOL)writeSnac:(SNAC *)aSnac;

@end
