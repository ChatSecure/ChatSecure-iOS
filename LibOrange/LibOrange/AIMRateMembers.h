//
//  AIMRateMembers.h
//  LibOrange
//
//  Created by Alex Nichol on 6/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "SNAC.h"


@interface AIMRateMembers : NSObject <OSCARPacket> {
    UInt16 classId;
	UInt16 numMembers;
	SNAC_ID * rateMembers;
}

@property (readonly) UInt16 classId;
@property (readonly) UInt16 numMembers;
@property (readonly) SNAC_ID * rateMembers;

@end
