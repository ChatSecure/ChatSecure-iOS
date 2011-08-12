//
//  AIMReceivingFileTransfer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMReceivingFileTransfer.h"

#define GOODBYE_TRANSFER(x,y,z) [x closeConnection];\
[self setIsTransferring:NO];\
[y closeFile];\
if (z) [self performSelector:@selector(_delegateInformDownloadFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];

@interface AIMReceivingFileTransfer (Private)

- (void)backgroundThread:(NSDictionary *)proposalInfo;
- (void)receiveFileDirectly:(OFTConnection *)theConnection cookie:(NSData *)cookie;
- (OFTConnection *)configureProxy:(NSString *)ipAddress port:(UInt16)port cookie:(NSData *)cookie sn:(NSString *)screenName;

- (void)_delegateInformCounterProp:(AIMIMRendezvous *)counter;
- (void)_delegateInformDownloadComplete;
- (void)_delegateInformDownloadFailed;
- (void)_delegateInformProgressChanged;

- (AIMIMRendezvous *)connectHereCounterProposal:(UInt16)port cookie:(NSData *)cookieData;

@end

@implementation AIMReceivingFileTransfer

@synthesize remoteHostAddr;
@synthesize remoteFileName;
@synthesize delegate;
@synthesize localUsername;
@synthesize writePath;

- (NSThread *)mainThread {
	[mainThreadLock lock];
	NSThread * theMainThread = mainThread;
	[mainThreadLock unlock];
	return theMainThread;
}

- (void)setMainThread:(NSThread *)_mainThread {
	[mainThreadLock lock];
	[mainThread autorelease];
	mainThread = [_mainThread retain];
	[mainThreadLock unlock];
}

- (NSThread *)backgroundThread {
	[bgThreadLock lock];
	NSThread * bgThread = backgroundThread;
	[bgThreadLock unlock];
	return bgThread;
}

- (void)setBackgroundThread:(NSThread *)_backgroundThread {
	[bgThreadLock lock];
	[backgroundThread autorelease];
	backgroundThread = [_backgroundThread retain];
	[bgThreadLock unlock];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<AIMFileTransfer name=\"%@\" source=\"%@ (%@)\">", self.remoteFileName, self.buddy, remoteHostAddr];
}

- (void)tryProposal {
	if (!bgThreadLock) {
		bgThreadLock = [[NSLock alloc] init];
	}
	if (!mainThreadLock) {
		mainThreadLock = [[NSLock alloc] init];
	}
	NSAssert(!self.backgroundThread, @"Background thread already running");
	
	NSString * ipCopy = [[[self lastProposal] remoteAddress] copy];
	NSString * internalIpCopy = [[[self lastProposal] internalAddress] copy];
	NSString * proxyIpCopy = [[[self lastProposal] proxyAddress] copy];
	UInt16 port = [[self lastProposal] remotePort];
	BOOL isProxy = [[self lastProposal] isProxyFlagSet];
	NSNumber * proxyFlag = [NSNumber numberWithBool:isProxy];
	NSNumber * step = [NSNumber numberWithInt:[[self lastProposal] sequenceNumber]];
	NSData * cookieDataCopy = [[[self cookie] cookieData] copy];
	NSString * snCopy = [self.localUsername copy]; // TODO: make this async.
	
	if (!internalIpCopy) internalIpCopy = [@"" retain];
	if (!ipCopy) ipCopy = [@"" retain];
	
	NSDictionary * connectInf = [NSDictionary dictionaryWithObjectsAndKeys:ipCopy, @"IP", internalIpCopy, @"IN_IP", [NSNumber numberWithInt:port], @"Port", proxyFlag, @"Proxy", proxyIpCopy, @"ProxyAddr", step, @"Seq", snCopy, @"SN", cookieDataCopy, @"CookieData", nil];
	
	[proxyIpCopy release];
	[ipCopy release];
	[internalIpCopy release];
	[cookieDataCopy release];
	[snCopy release];
	
	self.mainThread = [NSThread currentThread];
	self.backgroundThread = [[[NSThread alloc] initWithTarget:self selector:@selector(backgroundThread:) object:connectInf] autorelease];
	[self.backgroundThread start];
}

- (void)backgroundThread:(NSDictionary *)proposalInfo {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * ipAddr = [proposalInfo objectForKey:@"IP"];
	NSString * internalAddr = [proposalInfo objectForKey:@"IN_IP"];
	NSString * sn = [proposalInfo objectForKey:@"SN"];
	NSString * proxyIp = [proposalInfo objectForKey:@"ProxyAddr"];
	NSData * cookieData = [proposalInfo objectForKey:@"CookieData"];
	// UInt16 stage = [[proposalInfo objectForKey:@"Seq"] unsignedShortValue];
	
	UInt16 port = (UInt16)[[proposalInfo objectForKey:@"Port"] intValue];
	// UInt16 sequenceNumber = (UInt16)[[proposalInfo objectForKey:@"Seq"] intValue];
	BOOL useProxy = [[proposalInfo objectForKey:@"Proxy"] boolValue];
	if (useProxy) {
		OFTConnection * proxyConn = nil;
		if (!(proxyConn = [self configureProxy:proxyIp port:port cookie:cookieData sn:sn])) {
			// NSLog(@"Proxy connection failed to load.");
			[self performSelector:@selector(_delegateInformDownloadFailed) onThread:self.mainThread withObject:nil waitUntilDone:NO];
		} else {
			// NSLog(@"Proxy connected!");
			if ([delegate respondsToSelector:@selector(aimReceivingFileTransferSendAccept:)]) {
				[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferSendAccept:) onThread:self.mainThread withObject:self waitUntilDone:NO];
			}
			[self receiveFileDirectly:proxyConn cookie:cookieData];
		}
	} else {
		OFTConnection * connection = [[OFTConnection alloc] initWithHost:ipAddr port:port];
		if (!connection) {
			OFTConnection * connection = [[OFTConnection alloc] initWithHost:internalAddr port:port];
			if (!connection) {
				// generate counter proposal.
				UInt16 port = (UInt16)((arc4random() % (65535 - 6000)) + 6000);
				// NSLog(@"Proposal port: %d", port);
				AIMIMRendezvous * counterProp = [self connectHereCounterProposal:port cookie:cookieData];
				OFTServer * server = [[OFTServer alloc] initWithPort:port];
				[self performSelector:@selector(_delegateInformCounterProp:) onThread:self.mainThread withObject:counterProp waitUntilDone:NO];
				// NSLog(@"Opening port, generating proposal for it.");
				int fd = [server fileDescriptorForListeningOnPort:30]; // 30 second timeout.
				[server closeServer];
				[server release];
				if (fd < 0) {
					self.backgroundThread = nil;
					[pool drain];
					return;
				} else {
					NSLog(@"Got connect to ourselves.");
					OFTConnection * connection = [[OFTConnection alloc] initWithFileDescriptor:fd];
					[self receiveFileDirectly:connection cookie:cookieData];
					[connection release];
				}
			} else {
				NSLog(@"Connect success (internal IP)... start downloading the file.");
				if ([delegate respondsToSelector:@selector(aimReceivingFileTransferSendAccept:)]) {
					[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferSendAccept:) onThread:self.mainThread withObject:self waitUntilDone:NO];
				}
				[self receiveFileDirectly:connection cookie:cookieData];
				[connection release];
			}
		} else {
			// get the file.
			// NSLog(@"Connect success (external IP)... start downloading the file.");
			if ([delegate respondsToSelector:@selector(aimReceivingFileTransferSendAccept:)]) {
				[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferSendAccept:) onThread:self.mainThread withObject:self waitUntilDone:NO];
			}
			[self receiveFileDirectly:connection cookie:cookieData];
			[connection release];
		}
	}
	
	self.backgroundThread = nil;
	[pool drain];
}

- (void)newProposal {
	// if it's accepting, it will die silently.
	[self.backgroundThread cancel];
	self.backgroundThread = nil;
	[self tryProposal];
}

- (void)cancelDownload {
	[self.backgroundThread cancel];
	self.backgroundThread = nil;
}

- (AIMIMRendezvous *)connectHereCounterProposal:(UInt16)port cookie:(NSData *)cookieData {
	// get our IP address.
	UInt32 ipAddress = [ANIPInformation ipAddressGuess];
	UInt32 ipAddrConf =  ipAddress ^ 0xFFFFFFFF;
	UInt16 portDat = flipUInt16(port);
	UInt16 portConf = portDat ^ 0xFFFF;
	UInt16 requestNumFlip = flipUInt16(2);
	TLV * tIpAddr = [[TLV alloc] initWithType:TLV_RV_IP_ADDR data:[NSData dataWithBytes:&ipAddress length:4]];
	TLV * tClientAddr = [[TLV alloc] initWithType:TLV_RV_PROPOSER_IP_ADDR data:[NSData dataWithBytes:&ipAddress length:4]];
	TLV * tIpAddrXor = [[TLV alloc] initWithType:TLV_RV_IP_ADDR_XOR data:[NSData dataWithBytes:&ipAddrConf length:4]];
	TLV * tPort = [[TLV alloc] initWithType:TLV_RV_PORT data:[NSData dataWithBytes:&portDat length:2]];
	TLV * tPortXor = [[TLV alloc] initWithType:TLV_RV_PORT_XOR data:[NSData dataWithBytes:&portConf length:2]];
	TLV * reqNumber = [[TLV alloc] initWithType:TLV_RV_SEQUENCE_NUM data:[NSData dataWithBytes:&requestNumFlip length:2]];
	AIMIMRendezvous * rendezvous = [[AIMIMRendezvous alloc] init];
	rendezvous.cookie = [[[AIMICBMCookie alloc] initWithCookieData:[cookieData bytes]] autorelease];
	rendezvous.service = [[[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer] autorelease];
	rendezvous.type = RV_TYPE_PROPOSE;
	rendezvous.params = [NSArray arrayWithObjects:reqNumber, tIpAddr, tIpAddrXor, tClientAddr, tPort, tPortXor, nil];
	[tIpAddr release];
	[tClientAddr release];
	[tIpAddrXor release];
	[tPort release];
	[tPortXor release];
	[reqNumber release];
	return [rendezvous autorelease];
}

#pragma mark Informing

- (void)_delegateInformCounterProp:(AIMIMRendezvous *)counter {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimReceivingFileTransferPropositionFailed:counterProposal:)]) {
		[delegate aimReceivingFileTransferPropositionFailed:self counterProposal:counter];
	}
}

- (void)_delegateInformDownloadComplete {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimReceivingFileTransferFinished:)]) {
		[delegate aimReceivingFileTransferFinished:self];
	}
}

- (void)_delegateInformDownloadFailed {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimReceivingFileTransferTransferFailed:)]) {
		[delegate aimReceivingFileTransferTransferFailed:self];
	}
}

- (void)_delegateInformProgressChanged {
	NSAssert([NSThread currentThread] == self.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimReceivingFileTransferProgressChanged:)]) {
		[delegate aimReceivingFileTransferProgressChanged:self];
	}
}

#pragma mark Direct Connection

- (void)receiveFileDirectly:(OFTConnection *)theConnection cookie:(NSData *)_cookie {
	[self setIsTransferring:YES];
	if ([delegate respondsToSelector:@selector(aimReceivingFileTransferStarted:)]) {
		[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferStarted:) onThread:self.mainThread withObject:self waitUntilDone:NO];
	}
	OFTHeader * header = [theConnection readHeader:30];
	if ([header type] != OFT_TYPE_PROMPT) {
		GOODBYE_TRANSFER(theConnection, (id)nil, YES);
		return;
	}
	if (header.filesLeft > 1 || header.encrypt != 0 || header.compress != 0 || header.totalFiles > 1) {
		GOODBYE_TRANSFER(theConnection, (id)nil, YES);
		return;
	}
	// send acknowlege
	header.type = OFT_TYPE_ACKNOWLEDGE;
	header.cookie = _cookie;
	if (![theConnection writeHeader:header]) {
		GOODBYE_TRANSFER(theConnection, (id)nil, YES);
		return;
	}
	
	if ([[NSThread currentThread] isCancelled]) {
		GOODBYE_TRANSFER(theConnection, (id)nil, NO);
		return;
	}
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.writePath]) {
		[[NSFileManager defaultManager] createFileAtPath:self.writePath contents:[NSData data] attributes:nil];
	}
	NSFileHandle * fh = [NSFileHandle fileHandleForWritingAtPath:self.writePath];
	if (!fh) {
		GOODBYE_TRANSFER(theConnection, fh, YES);
		return;
	}
	char buffer[65536];
	header.receivedChecksum = 0xFFFF0000;
	UInt32 fileSize = [header totalSize] - [header resourceForkSize];
	// read only the file data, ignoring the resource fork data.
	while ([header bytesReceived] < fileSize) {
		int needs = (fileSize - [header bytesReceived] > 65536 ? 65536 : (fileSize - [header bytesReceived]));
		if ([[NSThread currentThread] isCancelled]) {
			GOODBYE_TRANSFER(theConnection, fh, NO);
			return;
		}
		int readSize = (int)read([theConnection fileDescriptor], buffer, needs);
		if ([[NSThread currentThread] isCancelled]) {
			GOODBYE_TRANSFER(theConnection, fh, NO);
			return;
		}
		if (readSize <= 0) {
			GOODBYE_TRANSFER(theConnection, fh, YES);
			return;
		}
		NSData * theData = [[NSData alloc] initWithBytes:buffer length:readSize];
		[fh writeData:theData];
		[theData release];
		// rolling checksum
		header.receivedChecksum = peer_oft_checksum_chunk((const unsigned char *)buffer, readSize, [header receivedChecksum], [header bytesReceived] & 1);
		[header setBytesReceived:([header bytesReceived] + readSize)];
		[self setProgress:((float)[header bytesReceived] / (float)fileSize)];
		[self performSelector:@selector(_delegateInformProgressChanged) onThread:self.mainThread withObject:nil waitUntilDone:NO];
	}
	// read the resource fork that trails the file data, do nothing with it.
	header.recvResourceForkCheckSum = 0xFFFF0000;
	while ([header bytesReceived] < [header totalSize]) {
		int needs = ([header totalSize] - [header bytesReceived] > 65536 ? 65536 : ([header totalSize] - [header bytesReceived]));
		if ([[NSThread currentThread] isCancelled]) {
			GOODBYE_TRANSFER(theConnection, fh, NO);
			return;
		}
		int readSize = (int)read([theConnection fileDescriptor], buffer, needs);
		if ([[NSThread currentThread] isCancelled]) {
			GOODBYE_TRANSFER(theConnection, fh, NO);
			return;
		}
		if (readSize <= 0) {
			GOODBYE_TRANSFER(theConnection, fh, YES);
			return;
		}
		// rolling checksum
		header.recvResourceForkCheckSum = peer_oft_checksum_chunk((const unsigned char *)buffer, readSize, [header recvResourceForkCheckSum], [header bytesReceived] % 2);
		[header setBytesReceived:([header bytesReceived] + readSize)];
	}
	[fh closeFile];
	fh = nil;
	
	header.type = OFT_TYPE_DONE;
	if (![theConnection writeHeader:header]) {
		GOODBYE_TRANSFER(theConnection, fh, YES);
		return;
	}
	
	[self performSelector:@selector(_delegateInformDownloadComplete) onThread:self.mainThread withObject:nil waitUntilDone:NO];
	
	[self setIsTransferring:NO];
	[theConnection closeConnection];
}

- (OFTConnection *)configureProxy:(NSString *)ipAddress port:(UInt16)port cookie:(NSData *)_cookie sn:(NSString *)screenName {
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

- (void)dealloc {
	self.remoteHostAddr = nil;
	self.remoteFileName = nil;
	self.mainThread = nil;
	self.backgroundThread = nil;
	self.delegate = nil;
	self.localUsername = nil;
	self.writePath = nil;
	[mainThreadLock release];
	[bgThreadLock release];
	[super dealloc];
}

@end
