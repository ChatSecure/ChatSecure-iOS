//
//  AIMICBMClientErr.h
//  LibOrange
//
//  Created by Alex Nichol on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMICBMCookie.h"
#import "SNAC.h"
#import "NSMutableData+FlipBit.h"

@interface AIMICBMClientErr : NSObject {
    AIMICBMCookie * cookie;
	UInt16 channel;
	NSString * loginID;
	UInt16 code;
	NSData * errorInfo; // rest of snac;
}

@property (nonatomic, retain) AIMICBMCookie * cookie;
@property (readwrite) UInt16 channel;
@property (nonatomic, retain) NSString * loginID;
@property (readwrite) UInt16 code;
@property (nonatomic, retain) NSData * errorInfo; // rest of snac;

- (id)initWithSNAC:(SNAC *)incomingSnac;
- (SNAC *)encodeOutgoingSnac:(UInt32)reqID;

@end
