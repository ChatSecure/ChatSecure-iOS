//
//  TLV.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "flipbit.h"
#import "TLV_Types.h"

@interface TLV : NSObject <OSCARPacket> {
	UInt16 type;
	NSData * tlvData;
}

@property (readwrite) UInt16 type;
@property (nonatomic, retain) NSData * tlvData;

- (id)initWithType:(UInt16)_type data:(NSData *)_tlvData;

- (UInt16)flippedType;
- (UInt16)flippedLength;

// decode a plain array, no start.
+ (NSArray *)decodeTLVArray:(NSData *)arrayData;
+ (NSData *)encodeTLVArray:(NSArray *)array;

// decode a UInt16 (count) followed by that many elements.
+ (NSArray *)decodeTLVBlock:(const char *)ptr length:(int *)length;

// decode a UInt16 (length) followed by that many bytes of elements.
+ (NSArray *)decodeTLVLBlock:(const char *)ptr length:(int *)length;

// encode TLVBlock (count + data)
+ (NSData *)encodeTLVBlock:(NSArray *)tlvs;

// encode TLVLBlock (length + data)
+ (NSData *)encodeTLVLBlock:(NSArray *)tlvs;

@end
