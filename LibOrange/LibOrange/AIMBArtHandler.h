//
//  AIMBArtHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNAC.h"
#import "AIMBArtIDWName.h"
#import "OSCARConnection.h"
#import "AIMSession.h"
#import "AIMBuddyIcon.h"
#import "AIMBArtDownloadReply.h"

#define BART_STATUS_CODE_SUCCESS 0
#define BART_STATUS_CODE_INVALID 1
#define BART_STATUS_CODE_NOCUSTOM 2
#define BART_STATUS_CODE_TOSMALL 3
#define BART_STATUS_CODE_TOBIG 4
#define BART_STATUS_CODE_INVALID_TYPE 5
#define BART_STATUS_CODE_BANNED 6
#define BART_STATUS_CODE_NOTFOUND 7


@class AIMBArtHandler;

@protocol AIMBArtHandlerDelegate <NSObject>

@optional
- (void)aimBArtHandlerConnectedToBArt:(AIMBArtHandler *)handler;
- (void)aimBArtHandlerConnectFailed:(AIMBArtHandler *)handler;
- (void)aimBArtHandlerDisconnected:(AIMBArtHandler *)handler;
- (void)aimBArtHandler:(AIMBArtHandler *)handler gotBuddyIcon:(AIMBuddyIcon *)icns forUser:(NSString *)loginID;
- (void)aimBArtHandler:(AIMBArtHandler *)handler uploadedBArtID:(AIMBArtID *)newBartID;
- (void)aimBArtHandler:(AIMBArtHandler *)handler uploadFailed:(UInt16)statusCode;

@end

@interface AIMBArtHandler : NSObject <AIMSessionHandler, OSCARConnectionDelegate> {
    NSString * bartHost;
	NSData * bartCookie;
	OSCARConnection * currentConnection;
	AIMSession * bossSession;
	id<AIMBArtHandlerDelegate> delegate;
}

@property (nonatomic, retain) id<AIMBArtHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)aSession;
- (BOOL)startupBArt;
- (void)closeBArtConnection;

- (BOOL)fetchBArtIcon:(AIMBArtID *)bartID forUser:(NSString *)username;
- (BOOL)uploadBArtData:(NSData *)data forType:(UInt16)bartType;

@end
