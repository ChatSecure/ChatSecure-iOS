//
//  AIMFeedbagItem.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLV.h"
#import "BasicStrings.h"
#import "OSCARPacket.h"

#define FEEDBAG_BUDDY 0
#define FEEDBAG_GROUP 1
#define FEEDBAG_PERMIT 2
#define FEEDBAG_DENY 3
#define FEEDBAG_PDINFO 4
#define FEEDBAG_BUDDY_PREFS 5
#define FEEDBAG_NONBUDDY 6
#define FEEDBAG_CLIENT_PREFS 9
#define FEEDBAG_DATE_TIME 15
#define FEEDBAG_BART 20
#define FEEDBAG_RB_ORDER 21
#define FEEDBAG_PERSONALITY 22
#define FEEDBAG_AL_PROF 23
#define FEEDBAG_AL_INFO 24
#define FEEDBAG_INTERACTION 25
#define FEEDBAG_VANITY_INFO 29
#define FEEDBAG_FAVORITE_LOCATION 30
#define FEEDBAG_BART_PDINFO 31
#define FEEDBAG_CUSTOM_EMOTICONS 36

#define FEEDBAG_ATTRIBUTE_ORDER 200
#define FEEDBAG_ATTRIBUTE_PD_MODE 202
#define FEEDBAG_ATTRIBUTE_PD_MASK 203
#define FEEDBAG_ATTRIBUTE_PD_FLAGS 204
#define FEEDBAG_ATTRIBUTE_BART_INFO 213

@interface AIMFeedbagItem : NSObject <OSCARPacket> {
	NSString * itemName; // max: 97 chars
	UInt16 groupID;
	UInt16 itemID;
	UInt16 classID;
	NSMutableArray * attributes;
}

@property (nonatomic, retain) NSString * itemName;
@property (readwrite) UInt16 groupID;
@property (readwrite) UInt16 itemID;
@property (readwrite) UInt16 classID;
@property (nonatomic, retain) NSMutableArray * attributes;

- (TLV *)attributeOfType:(UInt16)type;
+ (NSArray *)decodeArray:(NSData *)arrayData;

@end
