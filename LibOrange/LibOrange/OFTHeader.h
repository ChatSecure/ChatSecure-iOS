//
//  OFTHeader.h
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDescriptors.h"
#import "NSMutableData+FlipBit.h"

// some default values
#define kProtoVer 0x4F465432
#define kIDString @"Cool FileXfer"
#define kNameOffset 0x1c
#define kSizeOffset 0x11

// header types
#define OFT_TYPE_PROMPT 0x0101
#define OFT_TYPE_ACKNOWLEDGE 0x0202
#define OFT_TYPE_DONE 0x0204
// TODO: implement receiver resume.
#define OFT_TYPE_RECEIVER_RESUME 0x0205
#define OFT_TYPE_SENDER_RESUME 0x0106
#define OFT_TYPE_RESUME_ACK 0x0207

/**
 * This class allows you to read/write OFT headers from a file descriptor.  Many
 * methods listed here are similar to that of OSCARPacket.
 *
 * All properties of this class are editable.  This is to allow rolling checksums, type
 * changing, and more.
 */
@interface OFTHeader : NSObject {
    UInt32 protocolVersion;
	UInt16 length;
	UInt16 type;
	NSData * cookie;
	UInt16 encrypt;
	UInt16 compress;
	UInt16 totalFiles;
	UInt16 filesLeft;
	UInt16 totalParts;
	UInt16 partsLeft;
	UInt32 totalSize;
	UInt32 size;
	UInt32 modTime;
	UInt32 checkSum;
	UInt32 recvResourceForkCheckSum;
	UInt32 resourceForkSize;
	UInt32 creTime;
	UInt32 resourceForkChecksum;
	UInt32 bytesReceived;
	UInt32 receivedChecksum;
	NSString * idString;
	UInt8 flags;
	UInt8 nameOff;
	UInt8 sizeOff;
	NSData * dummy;
	NSData * macFileInf;
	UInt16 encoding;
	UInt16 subcode;
	NSString * fileName;
}

@property (readwrite) UInt32 protocolVersion;
@property (readwrite) UInt16 length;
@property (readwrite) UInt16 type;
@property (nonatomic, retain) NSData * cookie;
@property (readwrite) UInt16 encrypt;
@property (readwrite) UInt16 compress;
@property (readwrite) UInt16 totalFiles;
@property (readwrite) UInt16 filesLeft;
@property (readwrite) UInt16 totalParts;
@property (readwrite) UInt16 partsLeft;
@property (readwrite) UInt32 totalSize;
@property (readwrite) UInt32 size;
@property (readwrite) UInt32 modTime;
@property (readwrite) UInt32 checkSum;
@property (readwrite) UInt32 recvResourceForkCheckSum;
@property (readwrite) UInt32 resourceForkSize;
@property (readwrite) UInt32 creTime;
@property (readwrite) UInt32 resourceForkChecksum;
@property (readwrite) UInt32 bytesReceived;
@property (readwrite) UInt32 receivedChecksum;
@property (nonatomic, retain) NSString * idString;
@property (readwrite) UInt8 flags;
@property (readwrite) UInt8 nameOff; 
@property (readwrite) UInt8 sizeOff;
@property (nonatomic, retain) NSData * dummy;
@property (nonatomic, retain) NSData * macFileInf;
@property (readwrite) UInt16 encoding;
@property (readwrite) UInt16 subcode;
@property (nonatomic, retain) NSString * fileName;

- (id)initByReadingFD:(int)fileDesc;
- (NSData *)encodePacket;
- (BOOL)writeFileFD:(int)fileDesc;

@end
