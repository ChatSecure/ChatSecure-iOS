//
//  OSCARConnection.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#import <Foundation/Foundation.h>
#import "flipbit.h"
#import "FLAPFrame.h"

@class OSCARConnection;

@protocol OSCARConnectionDelegate<NSObject>

@optional
- (void)oscarConnectionClosed:(OSCARConnection *)connection;
- (void)oscarConnectionPacketWaiting:(OSCARConnection *)connection;

@end

typedef enum {
	OSCARConnectionStateUnopened,
	OSCARConnectionStateOpen,
	OSCARConnectionStateClosedByPeer,
	OSCARConnectionStateClosedByUser
} OSCARConnectionState;


@interface OSCARConnection : NSObject {
	NSLock * socketfdLock;
	int _socketfd;
	int port;
	NSString * hostName;
	OSCARConnectionState state;
	NSLock * stateLock;
	BOOL isNonBlocking;
	
	NSThread * backgroundThread;
	NSThread * mainThread;
	NSMutableArray * buffer;
	
	id<OSCARConnectionDelegate> delegate;
	UInt16 sequenceNumber;
}

@property (readonly) NSString * hostName;
@property (readwrite) BOOL isNonBlocking;
@property (readonly) UInt16 sequenceNumber;
@property (nonatomic, assign) id<OSCARConnectionDelegate> delegate;

- (id)initWithHost:(NSString *)host port:(int)_port;
- (BOOL)connectToHost:(NSError **)error;

- (BOOL)isOpen;
- (BOOL)hasFlap;
- (FLAPFrame *)readFlap;

- (FLAPFrame *)createFlapChannel:(UInt8)channel data:(NSData *)contents;
- (BOOL)writeFlap:(FLAPFrame *)flap;

- (BOOL)disconnect;

@end
