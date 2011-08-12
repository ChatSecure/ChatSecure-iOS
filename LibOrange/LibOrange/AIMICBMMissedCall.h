//
//  AIMICBMMissedCall.h
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMNickWInfo.h"

#define MISSED_CALL_REASON_TOO_LARGE 1
#define MISSED_CALL_REASON_RATE_EXCEEDED 2
#define MISSED_CALL_REASON_EVIL_SENDER 4
#define MISSED_CALL_REASON_EVIL_RECEIVER 8


@interface AIMICBMMissedCall : NSObject <OSCARPacket> {
	UInt16 channel;
	AIMNickWInfo * senderInfo;
	UInt16 numMissed;
	UInt16 reason;
}

@property (readonly) UInt16 channel;
@property (readonly) AIMNickWInfo * senderInfo;
@property (readonly) UInt16 numMissed;
@property (readonly) UInt16 reason;

+ (NSArray *)decodeArray:(NSData *)listData;

@end
