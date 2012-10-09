//
//  AIMSessionManager.h
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMRateParamsReply.h"
#import "AIMLoginHostInfo.h"
#import "SNAC.h"
#import "TLV.h"

#import "AIMFeedbagHandler.h"
#import "AIMICBMHandler.h"
#import "AIMTempBuddyHandler.h"
#import "AIMStatusHandler.h"
#import "AIMBArtHandler.h"
#import "AIMRateLimitHandler.h"
#import "AIMRendezvousHandler.h"

#define kMinICBMInterval 200

@class AIMSessionManager;

@protocol AIMSessionManagerDelegate <NSObject>

@optional

- (void)aimSessionManagerSignedOn:(AIMSessionManager *)sender; 
- (void)aimSessionManagerSignonFailed:(AIMSessionManager *)sender;
- (void)aimSessionManagerSignedOff:(AIMSessionManager *)sender;

@end

/**
 * A session manager encapsulates a session, providing services
 * for buddy lists, status messages, regular messages, etc.
 */
@interface AIMSessionManager : NSObject <OSCARConnectionDelegate, AIMSessionDelegate> {
    AIMSession * session;
	OSCARConnection * initConn;
	NSThread * backgroundThread;
	NSThread * mainThread;
	UInt32 reqID;
	
	/* Temp Store */
	AIMFeedbagRights * feedbagRights;
	AIMNickWInfo * initialInfo;
	
	/* Handlers */
	AIMFeedbagHandler * feedbagHandler;
	AIMICBMHandler * messageHandler;
	AIMTempBuddyHandler * tempBuddyHandler;
	AIMStatusHandler * statusHandler;
	AIMBArtHandler * bartHandler; // nil by default.
	AIMRateLimitHandler * rateHandler;
	AIMRendezvousHandler * rendezvousHandler;
	
	id<AIMSessionManagerDelegate> delegate;
}

@property (nonatomic, retain) NSThread * backgroundThread;
@property (nonatomic, retain) NSThread * mainThread;
@property (readonly) AIMSession * session;
@property (nonatomic, assign) id<AIMSessionManagerDelegate> delegate;
@property (readonly) AIMFeedbagHandler * feedbagHandler;
@property (readonly) AIMICBMHandler * messageHandler;
@property (readonly) AIMTempBuddyHandler * tempBuddyHandler;
@property (readonly) AIMStatusHandler * statusHandler;
@property (readonly) AIMBArtHandler * bartHandler;
@property (readonly) AIMRateLimitHandler * rateHandler;
@property (readonly) AIMRendezvousHandler * rendezvousHandler;

+ (BOOL)signonClientOnline:(OSCARConnection *)connection;

/**
 * Creates a new session manager, which will start a new background thread on which
 * it will login to OSCAR.  Once this login process is complete, a delegate method
 * will be called, and the session can be passed around.
 */
- (id)initWithLoginHostInfo:(AIMLoginHostInfo *)hostInf delegate:(id<AIMSessionManagerDelegate>)delegate;

/**
 * Should be called directly after the signon is performed to indicate that the
 * API user wants to have access to buddy icons.  If this is not called externally,
 * buddy icon notifications will not be given, and buddy icons will not be settable.
 */
- (void)configureBuddyArt;

@end
