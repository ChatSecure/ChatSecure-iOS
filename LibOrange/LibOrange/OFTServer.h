//
//  OFTServer.h
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

// set this to prevent socket listening.
// this should pretty much always be 0.
#define kDONT_SERVE 0

@interface OFTServer : NSObject {
    int port;
	int fd;
}

/**
 * Creates a server on a specified port.
 */
- (id)initWithPort:(int)port;

/**
 * Listens for a connection on the port given by the initializer.
 * If the timeout (in seconds) is reached, -1 will be returned.
 * This will also be the case if the current thread is cancelled.
 */
- (int)fileDescriptorForListeningOnPort:(int)timeout;

- (void)closeServer;

@end
