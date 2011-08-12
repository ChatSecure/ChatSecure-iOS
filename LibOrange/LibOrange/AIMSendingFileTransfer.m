//
//  AIMSendingFileTransfer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSendingFileTransfer.h"

@interface AIMSendingFileTransfer (Private)

- (void)listenBackgroundThread:(NSDictionary *)info;
- (void)connectInBackground:(NSDictionary *)info;
- (OFTConnection *)connectToProxyWithCookie:(NSData *)theCookie;
- (void)handleConnection:(OFTConnection *)connection cookie:(NSData *)cookie file:(NSString *)path;
- (AIMIMRendezvous *)configureProxyProp:(UInt32)proxyHost port:(UInt16)port cookie:(NSData *)cookie;
- (OFTConnection *)connectRecvProxy:(NSString *)ipAddress port:(UInt16)port cookie:(NSData *)cookie sn:(NSString *)screenName;

// delegate informing
- (void)_delegateInformCounterProp:(AIMIMRendezvous *)counter;
- (void)_delegateInformTransferStarted;
- (void)_delegateInformTransferFailed;
- (void)_delegateInformTransferDone;
- (void)_delegateMakeSendAccept;

@end

@implementation AIMSendingFileTransfer

@synthesize localFile;
@synthesize delegate;
@synthesize theUsername;

- (id)init {
    if ((self = [super init])) {
		
    }
    return self;
}

- (AIMIMRendezvous *)initialProposal {
	NSFileHandle * fh = [NSFileHandle fileHandleForReadingAtPath:[self localFile]];
	if (!fh) return nil;
	[fh seekToEndOfFile];
	NSUInteger size = [fh offsetInFile];
	[fh closeFile];
	
	char * filenameEncoding = "us-ascii";
	UInt16 seqNum = flipUInt16(1);
	UInt32 ipAddr = [ANIPInformation ipAddressGuess];
	UInt32 ipAddrXor = ipAddr ^ 0xFFFFFFFF;
	UInt16 port = flipUInt16((UInt16)(arc4random() % (65535 - 1024)) + 1024);
	UInt16 portXor = port ^ 0xFFFF;
	UInt16 maxProto = flipUInt16(1);
	listenPort = flipUInt16(port);
	
	RVServiceData * sCaps = [[RVServiceData alloc] init];
	sCaps.fileName = [localFile lastPathComponent];
	sCaps.multipleFilesFlag = 1;
	sCaps.totalFileCount = 1;
	sCaps.totalBytes = (UInt32)size;
	
	if (![sCaps encodePacket]) {
		[sCaps release];
		return nil;
	}
	
	TLV * seqNumber = [[TLV alloc] initWithType:TLV_RV_SEQUENCE_NUM data:[NSData dataWithBytes:&seqNum length:2]];
	TLV * ipAddress = [[TLV alloc] initWithType:TLV_RV_IP_ADDR data:[NSData dataWithBytes:&ipAddr length:4]];
	TLV * xorIpAddress = [[TLV alloc] initWithType:TLV_RV_IP_ADDR_XOR data:[NSData dataWithBytes:&ipAddrXor length:4]];
	TLV * t_port = [[TLV alloc] initWithType:TLV_RV_PORT data:[NSData dataWithBytes:&port length:2]];
	TLV * t_portXor = [[TLV alloc] initWithType:TLV_RV_PORT_XOR data:[NSData dataWithBytes:&portXor length:2]];
	TLV * cliIp = [[TLV alloc] initWithType:TLV_RV_PROPOSER_IP_ADDR data:[NSData dataWithBytes:&ipAddr length:4]];
	TLV * fnameEnc = [[TLV alloc] initWithType:TLV_RV_FILENAME_ENCODING data:[NSData dataWithBytes:filenameEncoding length:8]];
	TLV * capabilityData = [[TLV alloc] initWithType:TLV_RV_SERVICE_DATA data:[sCaps encodePacket]];
	TLV * maxProtoVer = [[TLV alloc] initWithType:TLV_RV_MAX_PROTOCOL_VERSION data:[NSData dataWithBytes:&maxProto length:2]];
	[sCaps release];
	
	AIMIMRendezvous * rv = [[AIMIMRendezvous alloc] init];
	rv.cookie = self.cookie;
	rv.service = [[[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer] autorelease];
	rv.type = RV_TYPE_PROPOSE;
	rv.params = [NSArray arrayWithObjects:seqNumber, ipAddress, xorIpAddress, cliIp, t_port, t_portXor, fnameEnc, capabilityData, maxProtoVer, nil];
	
	[seqNumber release];
	[ipAddress release];
	[xorIpAddress release];
	[t_port release];
	[t_portXor release];
	[cliIp release];
	[fnameEnc release];
	[capabilityData release];
	[maxProtoVer release];
	
	return [rv autorelease];
}

- (void)listenForConnect {
	NSData * cookieCopy = [[[[self cookie] cookieData] copy] autorelease];
	NSString * fileCopy = [[[self localFile] copy] autorelease];
	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:listenPort], @"port", cookieCopy, @"cookie", fileCopy, @"file", nil];
	self.mainThread = [NSThread currentThread];
	self.backgroundThread = [[[NSThread alloc] initWithTarget:self selector:@selector(listenBackgroundThread:) object:info] autorelease];
	[self.backgroundThread start];
}
- (void)gotCounterProposal {
	// NSLog(@"Counter prop");
	[self.backgroundThread cancel];
	self.backgroundThread = nil;
	NSString * propAddr = [[[[self lastProposal] internalAddress] copy] autorelease];
	NSString * externalAddr = [[[[self lastProposal] remoteAddress] copy] autorelease];
	NSNumber * port = [NSNumber numberWithInt:[[self lastProposal] remotePort]];
	NSNumber * proxy = [NSNumber numberWithBool:[[self lastProposal] isProxyFlagSet]];
	NSData * cookieCopy = [[[cookie cookieData] copy] autorelease];
	NSString * filenameCopy = [[[self localFile] copy] autorelease];
	NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:propAddr, @"host", externalAddr, @"vhost", cookieCopy, @"cookie", filenameCopy, @"file", proxy, @"proxy", port, @"port", nil];
	self.backgroundThread = [[[NSThread alloc] initWithTarget:self selector:@selector(connectInBackground:) object:userInfo] autorelease];
	[self.backgroundThread start];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<AIMSendingFileTransfer path=\"%@\" buddy=\"%@\">", self.localFile, self.buddy];
}

#pragma mark Background Thread

- (void)listenBackgroundThread:(NSDictionary *)info {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSAssert([NSThread currentThread] == self.backgroundThread, @"Running on incorrect thread");
	UInt16 port = [[info objectForKey:@"port"] unsignedShortValue];
	NSData * cookieData = [info objectForKey:@"cookie"];
	NSString * file = [info objectForKey:@"file"];
	// NSLog(@"Opening server on port %d", port);
	OFTServer * server = [[OFTServer alloc] initWithPort:port];
	int fd = [server fileDescriptorForListeningOnPort:0];
	[server closeServer];
	[server release];
	if ([[NSThread currentThread] isCancelled]) {
		[pool drain];
		return;
	}
	if (fd >= 0) {
		OFTConnection * connection = [[OFTConnection alloc] initWithFileDescriptor:fd];
		[self handleConnection:connection cookie:cookieData file:file];
		[connection release];
	}
	self.backgroundThread = nil;
	[pool drain];
}
- (void)connectInBackground:(NSDictionary *)info {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSAssert([NSThread currentThread] == self.backgroundThread, @"Running on incorrect thread");
	NSString * proposedAddress = [info objectForKey:@"host"];
	NSString * verifiedAddress = [info objectForKey:@"vhost"];
	NSData * cookieData = [info objectForKey:@"cookie"];
	NSString * file = [info objectForKey:@"file"];
	UInt16 port = [[info objectForKey:@"port"] unsignedShortValue];
	BOOL isProxy = [[info objectForKey:@"proxy"] boolValue];
	
	if (isProxy) {
		OFTConnection * connection = [self connectRecvProxy:proposedAddress port:port cookie:cookieData sn:self.theUsername];
		if (!connection) {
			[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		} else {
			[self handleConnection:connection cookie:cookieData file:file];
		}
	} else {
		// NSLog(@"Connect directly to peer.");
		OFTConnection * connection = nil;
		if (!kDONT_SERVE) {
			connection = [[OFTConnection alloc] initWithHost:proposedAddress port:port];
			if (!connection) {
				connection = [[OFTConnection alloc] initWithHost:verifiedAddress port:port];
			}
		}
		if (!connection) {
			// NSLog(@"Couldn't connect to peer.  Using proxy instead.");
			if (kDONT_SERVE) [NSThread sleepForTimeInterval:2]; // make it look like we tried.
			connection = [[self connectToProxyWithCookie:cookieData] retain];
		} else {
			// we connected to them, so send accept.
			[self performSelector:@selector(_delegateMakeSendAccept) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		}
		if (connection) {
			[self handleConnection:connection cookie:cookieData file:file];
			[connection release];
		} else {
			[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		}
	}
	self.backgroundThread = nil;
	[pool drain];
}
- (OFTConnection *)connectToProxyWithCookie:(NSData *)theCookie {
	NSAssert([NSThread currentThread] == self.backgroundThread, @"Running on incorrect thread");
	// NSLog(@"Connecting to proxy.");
	OFTConnection * theConnection = [[OFTConnection alloc] initWithHost:@"ars.oscar.aol.com" port:5190];
	if (!theConnection) return nil;
	OFTProxyConnection * proxy = [[OFTProxyConnection alloc] initWithFileDescriptor:[theConnection fileDescriptor]];
	if (!proxy) {
		[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		[theConnection closeConnection];
		[theConnection release];
		return nil;
	}
	NSMutableData * setupData = [[NSMutableData alloc] init];
	[setupData appendData:encodeString8(self.theUsername)];
	[setupData appendData:theCookie];
	[setupData appendData:[[AIMCapability filetransferCapabilitiesBlock] encodePacket]];
	OFTProxyCommand * command = [[OFTProxyCommand alloc] initWithCommandType:COMMAND_TYPE_INIT_SEND flags:0 cmdData:setupData];
	[setupData release];
	if (![proxy writeCommand:command]) {
		// NSLog(@"Failed to init send.");
		[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		[command release];
		[theConnection closeConnection];
		[theConnection release];
		[proxy release];
		return nil;
	}
	[command release];
	// get the ack.
	OFTProxyCommand * ack = [proxy readCommand];
	if (!ack || [ack commandType] != COMMAND_TYPE_ACKNOWLEDGE || [[ack commandData] length] != 6) {
		// NSLog(@"No proxy ack!!!!");
		[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		[theConnection closeConnection];
		[theConnection release];
		[proxy release];
		return nil;
	}
	const char * bytes = (const char *)[[ack commandData] bytes];
	UInt16 port = flipUInt16(*(const UInt16 *)bytes);
	UInt32 host = *(const UInt32 *)(&bytes[2]);
	// send the proposal and wait for ready.
	AIMIMRendezvous * prop = [self configureProxyProp:host port:port cookie:theCookie];
	[self performSelector:@selector(_delegateInformCounterProp:) onThread:self.mainThread withObject:prop waitUntilDone:NO];
	// await the host ready.
	OFTProxyCommand * hostReady = [proxy readCommand];
	if ([hostReady commandType] != COMMAND_TYPE_READY) {
		// NSLog(@"No ready packet.");
		[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		[theConnection closeConnection];
		[theConnection release];
		[proxy release];
		return nil;
	}
	// NSLog(@"Proxy configured successfully!");
	[proxy release];
	return [theConnection autorelease];
}
- (void)handleConnection:(OFTConnection *)connection cookie:(NSData *)theCookie file:(NSString *)path {
	// WIP
	NSAssert([NSThread currentThread] == self.backgroundThread, @"Running on incorrect thread");
	// NSLog(@"Send connection: %@", connection);
	[self performSelector:@selector(_delegateInformTransferStarted) onThread:self.mainThread withObject:nil waitUntilDone:NO];
	
	// calculate the checksum for the file.
	UInt32 checksum = 0xFFFF0000;
	NSFileHandle * fh = [NSFileHandle fileHandleForReadingAtPath:path];
	if (!fh) {
		// NSLog(@"Failed to read.");
		[connection closeConnection];
		return;
	}
	UInt32 hasRead = 0;
	while (true) {
		NSData * theData = [fh readDataOfLength:65536];
		if (!theData || [theData length] == 0) break;
		checksum = peer_oft_checksum_chunk([theData bytes], (int)[theData length], checksum, hasRead & 1);
		hasRead += [theData length];
	}
	
	OFTHeader * header = [[OFTHeader alloc] init];
	header.totalFiles = 1;
	header.totalParts = 1;
	header.filesLeft = 1;
	header.partsLeft = 1;
	header.flags = 0x20;
	header.fileName = [path lastPathComponent];
	header.checkSum = checksum;
	header.totalSize = hasRead;
	header.type = OFT_TYPE_PROMPT;
	header.size = hasRead;
	
	if (![connection writeHeader:header]) {
		[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		[header release];
		[connection closeConnection];
		[fh closeFile];
		return;
	}
	
	OFTHeader * response = [connection readHeader:30];
	if (!response || [response type] != OFT_TYPE_ACKNOWLEDGE || ![[response cookie] isEqualToData:theCookie]) {
		if (![[response cookie] isEqualToData:theCookie] && response) {
			NSLog(@"WARNING: Malicious attacks may be taking place; invalid cookie.");
		}
		[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		[header release];
		[connection closeConnection];
		[fh closeFile];
		return;
	}
	
	[header autorelease];
	// send the file's data like there's no tomorrow.
	[fh seekToFileOffset:0];
	while (true) {
		NSData * d = [fh readDataOfLength:65536];
		if ([d length] == 0 || !d) break;
		if (![connection writeData:d]) {
			[connection closeConnection];
			[fh closeFile];
			return;
		}
	}
	[fh closeFile];
	OFTHeader * done = [connection readHeader:60];
	if (!done || [done type] != OFT_TYPE_DONE) {
		[self performSelector:@selector(_delegateInformTransferFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		[connection closeConnection];
		return;
	}
	
	[self performSelector:@selector(_delegateInformTransferDone) onThread:self.mainThread withObject:nil waitUntilDone:NO];
	
	[connection closeConnection];
}
- (AIMIMRendezvous *)configureProxyProp:(UInt32)proxyHost port:(UInt16)port cookie:(NSData *)theCookie {
	// NSLog(@"Configure proxy proposal.");
	UInt16 reqNumFlip = flipUInt16(3);
	UInt16 portFlip = flipUInt16(port);
	UInt16 portXorB = 0xFFFF ^ portFlip;
	UInt32 hostXor = 0xFFFFFFFF ^ proxyHost;
	
	TLV * reqNumber = [[TLV alloc] initWithType:TLV_RV_SEQUENCE_NUM data:[NSData dataWithBytes:&reqNumFlip length:2]];
	TLV * proxyPort = [[TLV alloc] initWithType:TLV_RV_PORT data:[NSData dataWithBytes:&portFlip length:2]];
	TLV * portXor = [[TLV alloc] initWithType:TLV_RV_PORT_XOR data:[NSData dataWithBytes:&portXorB length:2]];
	TLV * proxyHostT = [[TLV alloc] initWithType:TLV_RV_IP_ADDR data:[NSData dataWithBytes:&proxyHost length:4]];
	TLV * proxyHostXor = [[TLV alloc] initWithType:TLV_RV_IP_ADDR_XOR data:[NSData dataWithBytes:&hostXor length:4]];
	TLV * proxyFlag = [[TLV alloc] initWithType:TLV_RV_REQUEST_USE_ARS data:[NSData data]];
	
	AIMIMRendezvous * rv = [[AIMIMRendezvous alloc] init];
	rv.service = [[[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer] autorelease];
	rv.type = RV_TYPE_PROPOSE;
	rv.cookie = [[[AIMICBMCookie alloc] initWithCookieData:[theCookie bytes]] autorelease];
	rv.params = [NSArray arrayWithObjects:reqNumber, proxyHostT, proxyHostXor, proxyPort, portXor, proxyFlag, nil];
	
	[reqNumber release];
	[proxyPort release];
	[portXor release];
	[proxyHostT release];
	[proxyHostXor release];
	[proxyFlag release];
	
	return [rv autorelease];
}

- (OFTConnection *)connectRecvProxy:(NSString *)ipAddress port:(UInt16)port cookie:(NSData *)_cookie sn:(NSString *)screenName {
	UInt16 actualPort = 5190;
	OFTConnection * realConnection = [[OFTConnection alloc] initWithHost:ipAddress port:actualPort];
	if (!realConnection) return nil;
	OFTProxyConnection * proxy = [[OFTProxyConnection alloc] initWithFileDescriptor:[realConnection fileDescriptor]];
	
	// configure the proxy.
	NSMutableData * initRecv = [[NSMutableData alloc] init];
	UInt8 snLen = (UInt8)[screenName length];
	UInt16 portFlip = flipUInt16(port);
	TLV * caps = [AIMCapability filetransferCapabilitiesBlock];
	[initRecv appendBytes:&snLen length:1];
	[initRecv appendData:[screenName dataUsingEncoding:NSASCIIStringEncoding]];
	[initRecv appendBytes:&portFlip length:2];
	[initRecv appendData:_cookie];
	[initRecv appendData:[caps encodePacket]];
	
	OFTProxyCommand * cmd = [[[OFTProxyCommand alloc] initWithCommandType:COMMAND_TYPE_INIT_RECV flags:0 cmdData:initRecv] autorelease];
	[initRecv release];
	if (![proxy writeCommand:cmd]) {
		[proxy release];
		[realConnection release];
		return nil;
	}
	OFTProxyCommand * conf = [proxy readCommand];
	if (!conf || [conf commandType] != COMMAND_TYPE_READY) {
		[proxy release];
		[realConnection release];
		return nil;
	}
	
	[proxy release];
	return [realConnection autorelease];
}

#pragma mark Delegate

- (void)_delegateInformCounterProp:(AIMIMRendezvous *)counter {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimSendingFileTransfer:sendCounterProp:)]) {
		[delegate aimSendingFileTransfer:self sendCounterProp:counter]; // it always should
	}
}
- (void)_delegateInformTransferStarted {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimSendingFileTransferStarted:)]) {
		[delegate aimSendingFileTransferStarted:self];
	}
}
- (void)_delegateInformTransferDone {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimSendingFileTransferFinished:)]) {
		[delegate aimSendingFileTransferFinished:self];
	}
}
- (void)_delegateInformTransferFailed {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimSendingFileTransferFailed:)]) {
		[delegate aimSendingFileTransferFailed:self];
	}
}
- (void)_delegateMakeSendAccept {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	UInt16 maxProtoVersion = flipUInt16(1);
	TLV * maxProto = [[TLV alloc] initWithType:TLV_RV_MAX_PROTOCOL_VERSION data:[NSData dataWithBytes:&maxProtoVersion length:2]];
	AIMIMRendezvous * acceptRV = [[AIMIMRendezvous alloc] init];
	acceptRV.type = RV_TYPE_ACCEPT;
	acceptRV.cookie = [self cookie];
	acceptRV.service = [[[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer] autorelease];
	acceptRV.params = [NSArray arrayWithObject:maxProto];
	[delegate aimSendingFileTransfer:self sendAccept:acceptRV];
	[acceptRV release];
	[maxProto release];
}

#pragma mark Synchronized Setters/Getters

// background thread
- (NSThread *)backgroundThread {
	if (!backgroundThreadSet) {
		backgroundThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (backgroundThreadSet) {
		if ([backgroundThreadSet count] != 1) return nil;
		return (NSThread *)[backgroundThreadSet anyObject];
	}
}
- (void)setBackgroundThread:(NSThread *)newBackgroundThread {
	if (!backgroundThreadSet) {
		backgroundThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (mainThreadSet) {
		[backgroundThreadSet removeAllObjects];
		if (newBackgroundThread) [backgroundThreadSet addObject:newBackgroundThread];
	}
}
// main thread
- (NSThread *)mainThread {
	if (!mainThreadSet) {
		mainThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (mainThreadSet) {
		if ([mainThreadSet count] != 1) return nil;
		return (NSThread *)[mainThreadSet anyObject];
	}
}
- (void)setMainThread:(NSThread *)newMainThread {
	if (!mainThreadSet) {
		mainThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (mainThreadSet) {
		[mainThreadSet removeAllObjects];
		if (newMainThread) [mainThreadSet addObject:newMainThread];
	}
}

- (void)dealloc {
	self.theUsername = nil;
	[mainThreadSet release];
	[backgroundThreadSet release];
	self.localFile = nil;
    [super dealloc];
}

@end
