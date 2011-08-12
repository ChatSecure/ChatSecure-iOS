//
//  AIMBArtID.h
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "flipbit.h"

#define BART_TYPE_BUDDY_ICON 1
#define BART_TYPE_STATUS_STR 2
#define BART_TYPE_CURRENT_AV_TRACK 15

#define BART_FLAG_CUSTOM 1
#define BART_FLAG_DATA 4
#define BART_FLAG_UNKNOWN 0x40
#define BART_FLAG_REDIRECT 0x80

@interface AIMBArtID : NSObject <OSCARPacket> {
	UInt16 type;
	UInt8 flags;
	UInt8 length;
	NSData * opaqueData;
}

@property (readonly) UInt16 type;
@property (readonly) UInt8 flags;
@property (readonly) UInt8 length;
@property (readonly) NSData * opaqueData;

- (id)initWithType:(UInt16)aType flags:(UInt8)theFlags opaqueData:(NSData *)theData;

+ (NSArray *)decodeArray:(NSData *)arrayData;
+ (NSData *)encodeArray:(NSArray *)array;

- (BOOL)dataFlagIsSet;
- (BOOL)isEqualToBartID:(AIMBArtID *)anotherID;

@end
