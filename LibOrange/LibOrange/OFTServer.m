//
//  OFTServer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OFTServer.h"


@implementation OFTServer


- (id)initWithPort:(int)thePort {
	if ((self = [super init])) {
		struct sockaddr_in serv_addr;
		int option_value = 1;
		
		fd = socket(AF_INET, SOCK_STREAM, 0);
		if (fd < 0) {
			[super dealloc];
			return nil;
		}
		
		bzero((char *)&serv_addr, sizeof(serv_addr));
		serv_addr.sin_family = AF_INET;
		serv_addr.sin_addr.s_addr = INADDR_ANY;
		serv_addr.sin_port = htons((UInt16)thePort);
		
		if (setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, (char *)&option_value, 
					   sizeof(option_value)) < 0) {
			NSLog(@"%@: WARNING: setsockopt failed.", NSStringFromClass([self class]));
		}
		
		if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (char *)&option_value, 
					   sizeof(option_value)) < 0) {
			NSLog(@"%@: WARNING: setsockopt failed.", NSStringFromClass([self class]));
		}
		
		if (!kDONT_SERVE) {
		
			if (bind(fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
				[super dealloc];
				return nil;
			}
			
			listen(fd, 5);
			
			/* Switch SO_LONGER and SO_KEEPALIVE to off. */
			struct linger l;
			l.l_onoff = 1;
			l.l_linger = 0;
			setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE|SO_LINGER, (char *)&l, sizeof(l));
			
		}
	}
	return self;
}

- (int)fileDescriptorForListeningOnPort:(int)timeout {
	if (kDONT_SERVE) {
		if (timeout > 0) {
			for (int i = 0; i < timeout; i++) {
				sleep(1);
				if ([[NSThread currentThread] isCancelled]) return -1;
			}
			return -1;
		} else {
			while (true) {
				sleep(1);
				if ([[NSThread currentThread] isCancelled]) return -1;
			}
			return -1;
		}
	}
	struct timeval timeoutV;
	int to = timeout > 5 ? 5 : timeout;
	if (timeout < 1) to = 5;
	timeoutV.tv_sec = to;
	timeoutV.tv_usec = 0;
	fd_set readFds;
	FD_ZERO(&readFds);
	FD_SET(fd, &readFds);
	int waited = 0;
	while ((select(fd + 1, &readFds, NULL, NULL, &timeoutV)) >= 0) {
		if ([[NSThread currentThread] isCancelled]) return -1;
		waited += to;
		if (FD_ISSET(fd, &readFds)) {
			int socket = accept(fd, NULL, NULL);
			return socket;
		} else {
			FD_SET(fd, &readFds);
		}
		if (waited > timeout && timeout > 1) return -1;
		timeoutV.tv_sec = to;
		timeoutV.tv_usec = 0;
	}
	return -1;
}

- (void)closeServer {
	if (fd == -1) return;
	close(fd);
	fd = -1;
}

- (void)dealloc {
	if (fd != -1) [self closeServer];
	[super dealloc];
}

@end
