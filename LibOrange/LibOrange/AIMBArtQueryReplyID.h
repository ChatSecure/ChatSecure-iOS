//
//  AIMBArtQueryReplyID.h
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBArtID.h"

@interface AIMBArtQueryReplyID : NSObject <OSCARPacket> {
    AIMBArtID * initialID;
	UInt8 replyCode;
	AIMBArtID * usedID;
}

@property (readonly) AIMBArtID * initialID;
@property (readonly) UInt8 replyCode;
@property (readonly) AIMBArtID * usedID;

@end
