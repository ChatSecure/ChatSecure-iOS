//
//  OFTProxyCommand.h
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "flipbit.h"
#import "FileDescriptors.h"

#define COMMAND_TYPE_READY 0x0005
#define COMMAND_TYPE_INIT_RECV 0x0004
#define COMMAND_TYPE_ACKNOWLEDGE 0x0003
#define COMMAND_TYPE_INIT_SEND 0x0002
#define COMMAND_TYPE_ERROR 0x0001

@interface OFTProxyCommand : NSObject {
	UInt16 length;
	UInt16 commandType;
	UInt16 flags;
	NSData * commandData;
}

@property (readonly) UInt16 length;
@property (readonly) UInt16 commandType;
@property (readonly) UInt16 flags;
@property (readonly) NSData * commandData;

- (id)initWithCommandType:(UInt16)cmdType flags:(UInt16)theFlags cmdData:(NSData *)cmdData;
- (id)initWithFileDescriptor:(int)fd;
- (NSData *)encodePacket;
- (BOOL)writeToFileDescriptor:(int)fd;

@end
