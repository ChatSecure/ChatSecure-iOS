//
//  OFTConnection.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OFTConnection.h"   

@interface OFTConnection (Private)

- (void)setState:(OFTConnectionState)newState;

@end

@implementation OFTConnection

- (OFTConnectionState)state {
	[stateLock lock];
	OFTConnectionState stateCopy = state;
	[stateLock unlock];
	return stateCopy;
}

- (void)setState:(OFTConnectionState)newState {
	[stateLock lock];
	state = newState;
	[stateLock unlock];
}

- (int)fileDescriptor {
	[fileDescriptorLock lock];
	int fd = fileDescriptor;
	[fileDescriptorLock unlock];
	return fd;
}

- (void)setFileDescriptor:(int)newFileDescriptor {
	[fileDescriptorLock lock];
	if (newFileDescriptor < 0 && fileDescriptor >= 0) {
		close(fileDescriptor);
	}
	fileDescriptor = newFileDescriptor;
	[fileDescriptorLock unlock];
}

/**
 * Attempts to create a new connection to a specific host and port.
 * If the connect fails, nil will be returned.
 */
- (id)initWithHost:(NSString *)host port:(UInt16)port {
	if ((self = [super init])) {
		stateLock = [[NSLock alloc] init];
		fileDescriptorLock = [[NSLock alloc] init];
		state = OFTConnectionStateUnopen;
		// TODO: connect socket here.
		struct sockaddr_in serv_addr;
		struct hostent * server;
		fileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
		if (fileDescriptor < 0) {
			[self dealloc];
			return nil;
		}
		
		server = gethostbyname([host UTF8String]);
		if (!server) {
			[self dealloc];
			return nil;
		}
		
		bzero(&serv_addr, sizeof(struct sockaddr_in));
		serv_addr.sin_family = AF_INET;
		// copy the address to our sockadd_in.
		bcopy(server->h_addr, &serv_addr.sin_addr.s_addr, server->h_length);
		serv_addr.sin_port = htons(port);
		
		// set non-blocking.
		fcntl(fileDescriptor, F_SETFL, O_NONBLOCK);
		
		connect(fileDescriptor, (const struct sockaddr *)&serv_addr, sizeof(struct sockaddr_in));
		
		fd_set fdset;
		struct timeval tv;
		FD_ZERO(&fdset);
		FD_SET(fileDescriptor, &fdset);
		tv.tv_sec = 3;			/* 10 second timeout */
		tv.tv_usec = 0;
		
		if (select(fileDescriptor + 1, NULL, &fdset, NULL, &tv) == 1) {
			int so_error;
			socklen_t len = sizeof so_error;
			getsockopt(fileDescriptor, SOL_SOCKET, SO_ERROR, &so_error, &len);
			if (so_error != 0) {
				close(fileDescriptor);
				[self dealloc];
				return nil;
			}
		} else {
			close(fileDescriptor);
			[self dealloc];
			return nil;
		}
		
		// set blocking.
		fcntl(fileDescriptor, F_SETFL, 0);
		
		state = OFTConnectionStateOpen;
	}
	return self;
}

/**
 * Creates an OFT connection with an existing file descriptor.
 */
- (id)initWithFileDescriptor:(int)fd {
	if ((self = [super init])) {
		stateLock = [[NSLock alloc] init];
		fileDescriptorLock = [[NSLock alloc] init];
		state = OFTConnectionStateOpen;
		fileDescriptor = fd;
	}
	return self;
}

- (OFTHeader *)readHeader:(int)timeoutSeconds {
	fd_set readFds;
	struct timeval tv;
	FD_ZERO(&readFds);
	FD_SET(self.fileDescriptor, &readFds);
	tv.tv_sec = timeoutSeconds;
	tv.tv_usec = 0;
	if (select(fileDescriptor + 1, &readFds, NULL, NULL, &tv) < 0) {
		return nil;
	}
	if (FD_ISSET(self.fileDescriptor, &readFds)) {
		OFTHeader * header = [[OFTHeader alloc] initByReadingFD:fileDescriptor];
		return [header autorelease];
	} else {
		return nil;
	}
}

- (BOOL)writeHeader:(OFTHeader *)theHeader {
	return [theHeader writeFileFD:fileDescriptor];
}

- (BOOL)writeData:(NSData *)data {
	int written = 0;
	const char * bytes = [data bytes];
	int toWrite = (int)[data length];
	while (written < toWrite) {
		int wrote = (int)write(fileDescriptor, &bytes[written], toWrite - written);
		if (wrote <= 0) {
			return NO;
		}
		written += wrote;
	}
	return YES;
}

- (void)closeConnection {
	if (self.state == OFTConnectionStateOpen) {
		self.state = OFTConnectionStateClosed;
		self.fileDescriptor = -1; // closes the socket.
	}
}

- (void)dealloc {
	[stateLock release];
	[fileDescriptorLock release];
	[super dealloc];
}

@end
