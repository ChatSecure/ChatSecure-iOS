//
//  OFTConnection.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OFTHeader.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

typedef enum {
	OFTConnectionStateUnopen,
	OFTConnectionStateOpen,
	OFTConnectionStateClosed
} OFTConnectionState;

@interface OFTConnection : NSObject {
	int fileDescriptor;
	OFTConnectionState state;
	NSLock * stateLock;
	NSLock * fileDescriptorLock;
}

@property (readwrite) int fileDescriptor;

/**
 * @return Returns the current state of the connection.
 */
- (OFTConnectionState)state;

/**
 * Attempts to create a new connection to a specific host and port.
 * If the connect fails, nil will be returned.
 */
- (id)initWithHost:(NSString *)host port:(UInt16)port;

/**
 * Creates an OFT connection with an existing file descriptor.
 */
- (id)initWithFileDescriptor:(int)fd;

- (OFTHeader *)readHeader:(int)timeoutSeconds;
- (BOOL)writeHeader:(OFTHeader *)theHeader;
- (BOOL)writeData:(NSData *)rawData;

- (void)closeConnection;

@end
