//
//  AIMSendingFileTransfer.h
//  LibOrange
//
//  Created by Alex Nichol on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFileTransfer.h"
#import "ANIPInformation.h"
#import "OFTConnection.h"
#import "OFTServer.h"
#import "OFTProxyConnection.h"
#import "BasicStrings.h"
#import "OFTCheckSum.h"
#import "FileDescriptors.h"

@class AIMSendingFileTransfer;

@protocol AIMSendingFileTransferDelegate <NSObject>

- (void)aimSendingFileTransfer:(AIMSendingFileTransfer *)ft sendCounterProp:(AIMIMRendezvous *)rv;
- (void)aimSendingFileTransfer:(AIMSendingFileTransfer *)ft sendAccept:(AIMIMRendezvous *)rv;

@optional
- (void)aimSendingFileTransferFailed:(AIMSendingFileTransfer *)ft;
- (void)aimSendingFileTransferStarted:(AIMSendingFileTransfer *)ft;
- (void)aimSendingFileTransferFinished:(AIMSendingFileTransfer *)ft;

@end

@interface AIMSendingFileTransfer : AIMFileTransfer {
    NSString * localFile;
	UInt16 listenPort;
	NSMutableSet * backgroundThreadSet;
	NSMutableSet * mainThreadSet;
	NSString * theUsername;
	id<AIMSendingFileTransferDelegate> delegate;
}

@property (nonatomic, retain) NSString * localFile;
@property (nonatomic, retain) NSString * theUsername;
@property (nonatomic, assign) id<AIMSendingFileTransferDelegate> delegate;

- (AIMIMRendezvous *)initialProposal;
- (void)listenForConnect;
- (void)gotCounterProposal;

// background thread
- (NSThread *)backgroundThread;
- (void)setBackgroundThread:(NSThread *)newBackgroundThread;
// main thread
- (NSThread *)mainThread;
- (void)setMainThread:(NSThread *)newMainThread;

@end
