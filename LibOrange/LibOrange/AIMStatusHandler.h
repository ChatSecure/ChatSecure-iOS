//
//  AIMStatusHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMNickWInfo.h"
#import "AIMNickWInfo+BArt.h"
#import "AIMNickWInfo+Update.h"
#import "AIMNickWInfo+Caps.h"
#import "AIMBArtHandler.h"

#import "AIMFeedbagHandler.h"
#import "FTSetBArtItem.h"

typedef enum {
	AIMIconUploadErrorTypeInvalid,
	AIMIconUploadErrorTypeTooBig,
	AIMIconUploadErrorTypeTooSmall,
	AIMIconUploadErrorTypeBanned,
	AIMIconUploadErrorTypeOther
} AIMIconUploadErrorType;

@class AIMStatusHandler;

@protocol AIMStatusHandlerDelegate<NSObject>

@optional
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status;
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyIconChanged:(AIMBlistBuddy *)theBuddy;
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyRejected:(NSString *)loginID;
- (void)aimStatusHandlerUserStatusUpdated:(AIMStatusHandler *)handler;
- (void)aimStatusHandlerBArtConnected:(AIMStatusHandler *)handler;
- (void)aimStatusHandler:(AIMStatusHandler *)handler setIconFailed:(AIMIconUploadErrorType)reason;

@end

@interface AIMStatusHandler : NSObject <AIMSessionHandler, AIMBArtHandlerDelegate> {
    AIMSession * session;
	AIMBuddyStatus * userStatus;
	id<AIMStatusHandlerDelegate> delegate;
	AIMNickWInfo * lastInfo;
	AIMBArtHandler * bartHandler;
	/* we need access to the feedbag handler so that we can add/update BArt items 
	   for the next signin. */
	AIMFeedbagHandler * feedbagHandler;
}

@property (readonly) AIMBuddyStatus * userStatus;
@property (nonatomic, assign) id<AIMStatusHandlerDelegate> delegate;
@property (nonatomic, retain) AIMBArtHandler * bartHandler;
@property (nonatomic, retain) AIMFeedbagHandler * feedbagHandler;

- (id)initWithSession:(AIMSession *)theSession initialInfo:(AIMNickWInfo *)initInfo;
- (void)queryUserInfo;
- (void)updateStatus:(AIMBuddyStatus *)newStatus;
- (void)updateUserIcon:(NSData *)newIcon;
- (void)configureBart;

@end
