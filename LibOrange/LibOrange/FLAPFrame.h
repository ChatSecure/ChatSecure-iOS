//
//  FLAPFrame.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "flipbit.h"

@interface FLAPFrame : NSObject <OSCARPacket> {
	UInt8 identifier; // must be '*'
	UInt8 channel; // 1, 2, 3, 4, 5
	UInt16 sequenceNumber; // step up every send.
	NSData * frameData;
}

@property (readwrite) UInt8 identifier;
@property (readwrite) UInt8 channel;
@property (readwrite) UInt16 sequenceNumber;
@property (nonatomic, retain) NSData * frameData;

- (id)initWithChannel:(UInt8)_channel sequenceNumber:(UInt16)_sequenceNumber data:(NSData *)_frameData;

- (UInt16)flippedSequenceNumber;
- (UInt16)flippedFrameLength;

@end
