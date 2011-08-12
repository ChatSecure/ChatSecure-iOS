//
//  OSCARConnection.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSCARConnection.h"

#define kMaxBufferSize 65536

@interface OSCARConnection (Private)

- (OSCARConnectionState)_state;
- (void)_setState:(OSCARConnectionState)newState;
- (int)socketfd;
- (void)setSocketfd:(int)newFd;

- (void)readInBackground:(NSThread *)mainThread;
- (void)packetWaiting;

@end

@implementation OSCARConnection

@synthesize hostName;
@synthesize isNonBlocking;
@synthesize sequenceNumber;
@synthesize delegate;

- (id)initWithHost:(NSString *)host port:(int)_port {
	if ((self = [super init])) {
		hostName = [host retain];
		port = _port;
		stateLock = [[NSLock alloc] init];
		socketfdLock = [[NSLock alloc] init];
		state = OSCARConnectionStateUnopened;
		isNonBlocking = NO;
		sequenceNumber = arc4random() % 0xFFFF;
	}
	return self;
}

- (BOOL)connectToHost:(NSError **)error {
	// first, launch the connection.
	if (state != OSCARConnectionStateUnopened) return NO;
	struct sockaddr_in serv_addr;
	struct hostent * server;
	self.socketfd = socket(AF_INET, SOCK_STREAM, 0);
	if (self.socketfd < 0) {
		if (error)
			*error = [NSError errorWithDomain:@"Socket creation failed" code:200 userInfo:nil];
		state = OSCARConnectionStateUnopened;
		return NO;
	}
	
	server = gethostbyname([hostName UTF8String]);
	if (!server) {
		if (error) 
			*error = [NSError errorWithDomain:@"No host" code:201 userInfo:nil];
		state = OSCARConnectionStateUnopened;
		return NO;
	}
	
	bzero(&serv_addr, sizeof(struct sockaddr_in));
	serv_addr.sin_family = AF_INET;
	// copy the address to our sockadd_in.
	bcopy(server->h_addr, &serv_addr.sin_addr.s_addr, server->h_length);
	serv_addr.sin_port = htons(port);
	
	if (connect(self.socketfd, (const struct sockaddr *)&serv_addr, sizeof(struct sockaddr_in)) < 0) {
		state = OSCARConnectionStateUnopened;
		if (error)
			*error = [NSError errorWithDomain:@"Connect failed" code:202 userInfo:nil];
	}
	
	buffer = [[NSMutableArray alloc] init];
	
	state = OSCARConnectionStateOpen;
	
	backgroundThread = [[NSThread alloc] initWithTarget:self
											   selector:@selector(readInBackground:)
												 object:[NSThread currentThread]];
	[backgroundThread start];
	
	return YES;
}

- (BOOL)isOpen {
	[stateLock lock];
	BOOL isOpen = (state == OSCARConnectionStateOpen);
	[stateLock unlock];
	return isOpen;
}

- (BOOL)hasFlap {
	if (![self isOpen]) return NO;
	int count = 0;
	@synchronized (buffer) {
		count = (int)[buffer count];
	}
	return (count > 0) ? YES : NO;
}

- (FLAPFrame *)readFlap {
	if (![self isOpen]) return nil;
	if (isNonBlocking && ![self hasFlap]) return nil;
	if ([self hasFlap]) {
		FLAPFrame * frame = nil;
		@synchronized (buffer) {
			if ([buffer count] < 1) return nil;
			frame = [[buffer objectAtIndex:0] retain];
			[buffer removeObjectAtIndex:0];
		}
		return [frame autorelease];
	} else if (!isNonBlocking) {
		while (![self hasFlap]) {
			if (![self isOpen]) {
				return nil;
			}
			[NSThread sleepForTimeInterval:0.1];
		}
		return [self readFlap];
	}
	return nil;
}

- (FLAPFrame *)createFlapChannel:(UInt8)channel data:(NSData *)contents {
	return [[[FLAPFrame alloc] initWithChannel:channel
								sequenceNumber:sequenceNumber++
										  data:contents] autorelease];
}

- (BOOL)writeFlap:(FLAPFrame *)flap {
	if (![self isOpen]) return NO;
	// we have to execute a write statement
	NSData * bufferData = [flap encodePacket];
	const char * bytes = [bufferData bytes];
	int toWrite = (int)[bufferData length];
	while (toWrite > 0) {
		int needsWritten = (toWrite <= kMaxBufferSize) ? toWrite : kMaxBufferSize;
		int wrote = (int)write(self.socketfd, &bytes[[bufferData length] - toWrite], needsWritten);
		if (wrote <= 0) {
			if ([self isOpen]) {
				[self _setState:OSCARConnectionStateClosedByPeer];
			}
			return NO;
		}
		toWrite -= wrote;
	}
	return YES;
}

- (BOOL)disconnect {
	if (![self isOpen]) return NO;
	[backgroundThread cancel];
	[backgroundThread release];
	backgroundThread = nil;

	[self _setState:OSCARConnectionStateClosedByUser];
	return YES;
}

- (void)dealloc {
	[backgroundThread release];
	[stateLock release];
	[socketfdLock release];
	[hostName release];
	[buffer release];
	[super dealloc];
}

#pragma mark Private

- (void)readInBackground:(NSThread *)_mainThread {
	mainThread = _mainThread;
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	[[mainThread retain] autorelease];
	
	while (![[NSThread currentThread] isCancelled]) {
		// first, await some data.
		int error;
		fd_set readDetector;
		struct timeval myVar;
		do {
			FD_ZERO(&readDetector);
			FD_SET(self.socketfd, &readDetector);
			myVar.tv_sec = 10;
			myVar.tv_usec = 0;
			error = select(self.socketfd + 1, &readDetector,
							   NULL, NULL, &myVar);
			if (error < 0) {
				if ([self _state] == OSCARConnectionStateOpen)
					[self _setState:OSCARConnectionStateClosedByPeer];
				[pool drain];
				return;
			}
		} while (!FD_ISSET(self.socketfd, &readDetector) && error <= 0 && [self isOpen]);
		
		if ([[NSThread currentThread] isCancelled] || ![self isOpen]) break;
		
		// here we read a header's length, and the data.
		int headerGot = 0;
		char headerData[6];
		while (headerGot < 6) {
			int justRead = (int)read(self.socketfd, &headerData[headerGot], 6 - headerGot);
			if (justRead <= 0) {
				if ([self _state] == OSCARConnectionStateOpen)
					[self _setState:OSCARConnectionStateClosedByPeer];
				[pool drain];
				return;
			}
			headerGot += justRead;
		}
		
		if ([[NSThread currentThread] isCancelled] || ![self isOpen]) break;
		
		UInt16 payloadLength = flipUInt16(((UInt16 *)headerData)[2]);
		int bytesNeeded = payloadLength;
		// read that many bytes!
		char * payload = (char *)malloc(payloadLength);
		while (bytesNeeded > 0) {
			int startIndex = payloadLength - bytesNeeded;
			int wants = (bytesNeeded <= kMaxBufferSize) ? bytesNeeded : kMaxBufferSize;
			int justRead = (int)read(self.socketfd, &payload[startIndex], wants);
			if (justRead <= 0) {
				free(payload);
				if ([self _state] == OSCARConnectionStateOpen)
					[self _setState:OSCARConnectionStateClosedByPeer];
				[pool drain];
				return;
			}
			bytesNeeded -= justRead;
		}
		
		NSMutableData * frameData = [[NSMutableData alloc] init];
		[frameData appendBytes:headerData length:6];
		[frameData appendBytes:payload length:payloadLength];
		free(payload);
		FLAPFrame * flap = [[FLAPFrame alloc] initWithData:frameData];
		[frameData release];
		
		// finally, add the packet and notify.
		@synchronized (buffer) {
			[buffer addObject:flap];
			[flap release];
		}
		
		if ([mainThread isExecuting]) [self performSelector:@selector(packetWaiting) onThread:mainThread withObject:nil waitUntilDone:NO];
	}
	
	if ([self _state] == OSCARConnectionStateOpen)
		[self _setState:OSCARConnectionStateClosedByPeer];
	
	[pool drain];
}

- (void)packetWaiting {
	NSAssert([NSThread currentThread] == mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(oscarConnectionPacketWaiting:)]) 
		[delegate oscarConnectionPacketWaiting:self];
}

#pragma mark Private

- (OSCARConnectionState)_state {
	[stateLock lock];
	OSCARConnectionState theState = state;
	[stateLock unlock];
	return theState;
}
- (void)_setState:(OSCARConnectionState)newState {
	[stateLock lock];
	BOOL wasClosed = NO;
	if (state == OSCARConnectionStateOpen && newState != OSCARConnectionStateOpen) {
		wasClosed = YES;
	}
	state = newState;
	[stateLock unlock];
	if (wasClosed) {
		if ([delegate respondsToSelector:@selector(oscarConnectionClosed:)]) {
			[(NSObject *)delegate performSelector:@selector(oscarConnectionClosed:) onThread:mainThread withObject:self waitUntilDone:NO];
		}
		[socketfdLock lock];
		close(_socketfd);
		_socketfd = -1;
		[socketfdLock unlock];
	}
}
- (int)socketfd {
	[socketfdLock lock];
	int sfd = _socketfd;
	[socketfdLock unlock];
	return sfd;
}
- (void)setSocketfd:(int)newFd {
	[socketfdLock lock];
	_socketfd = newFd;
	[socketfdLock unlock];
}

@end
