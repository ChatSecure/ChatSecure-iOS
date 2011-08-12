//
//  AIMRendezvousHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMReceivingFileTransfer.h"
#import "AIMIMRendezvous.h"
#import "AIMICBMMessageToServer.h"
#import "AIMSendingFileTransfer.h"
#import "AIMICBMClientErr.h"

@class AIMRendezvousHandler;

@protocol AIMRendezvousHandlerDelegate <NSObject>

@optional
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferRequested:(AIMReceivingFileTransfer *)ft;
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferCancelled:(AIMFileTransfer *)ft reason:(UInt16)reason;
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferStarted:(AIMFileTransfer *)ft;
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferFailed:(AIMFileTransfer *)ft;
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferDone:(AIMFileTransfer *)ft;
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferProgressChanged:(AIMFileTransfer *)ft;

@end

@interface AIMRendezvousHandler : NSObject <AIMSessionHandler, AIMReceivingFileTransferDelegate, AIMSendingFileTransferDelegate> {
    NSMutableArray * fileTransfers;
	AIMSession * session;
	id<AIMRendezvousHandlerDelegate> delegate;
}

@property (nonatomic, assign) id<AIMRendezvousHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)theSession;
- (AIMFileTransfer *)fileTransferWithCookie:(AIMICBMCookie *)cookie;

- (void)acceptFileTransfer:(AIMReceivingFileTransfer *)ft saveToPath:(NSString *)path;
- (void)cancelFileTransfer:(AIMFileTransfer *)ft;
- (AIMSendingFileTransfer *)sendFile:(NSString *)path toUser:(AIMBlistBuddy *)buddy;

@end
