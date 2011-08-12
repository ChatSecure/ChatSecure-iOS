//
//  AIMRateParams.h
//  LibOrange
//
//  Created by Alex Nichol on 6/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "flipbit.h"


@interface AIMRateParams : NSObject <OSCARPacket> {
	UInt16 classId;
	UInt32 windowSize;
	UInt32 clearThreshold;
	UInt32 alertThreshold;
	UInt32 limitThreshold;
	UInt32 disconnectThreshold;
	UInt32 currentAverage;
	UInt32 maxAverage;
	UInt32 lastArrivalDelta;
	UInt8 droppingSNACs;
}

@property (readonly) UInt16 classId;
@property (readonly) UInt32 windowSize;
@property (readonly) UInt32 clearThreshold;
@property (readonly) UInt32 alertThreshold;
@property (readonly) UInt32 limitThreshold;
@property (readonly) UInt32 disconnectThreshold;
@property (readonly) UInt32 currentAverage;
@property (readonly) UInt32 maxAverage;
@property (readonly) UInt32 lastArrivalDelta;
@property (readonly) UInt8 droppingSNACs;

@end
