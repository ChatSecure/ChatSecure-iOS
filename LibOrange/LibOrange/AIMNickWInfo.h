//
//  ANNickWInfo.h
//  ANInstantMessage
//
//  Created by Alex Nichol on 3/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLV.h"
#import "OSCARPacket.h"
#import "BasicStrings.h"

#define NICKFLAGS_UNCONFIRMED 0x1
#define NICKFLAGS_AOL 0x0004
#define NICKFLAGS_AIM 0x0010
#define NICKFLAGS_UNAVAILABLE 0x0020
#define NICKFLAGS_ICQ 0x0040
#define NICKFLAGS_WIRELESS 0x0080
#define NICKFLAGS_IMF 0x0200
#define NICKFLAGS_BOT 0x0400
#define NICKFLAGS_ONE_WAY_WIRELESS 0x1000
#define NICKFLAGS_NO_KNOCK_KNOCK 0x00040000
#define NICKFLAGS_FORWARD_MOBILE 0x00080000

@interface AIMNickWInfo : NSObject <OSCARPacket> {
	NSString * username;
	UInt16 evil;
	NSMutableArray * userAttributes;
}

@property (readwrite) UInt16 evil;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSMutableArray * userAttributes;

- (UInt16)nickFlags;
- (TLV *)attributeOfType:(UInt16)attribute;

+ (NSArray *)decodeArray:(NSData *)arrayOfNicks;

@end
