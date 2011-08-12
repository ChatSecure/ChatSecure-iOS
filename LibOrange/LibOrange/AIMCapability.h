//
//  AIMCapability.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLV.h"

typedef enum {
	AIMCapabilityFileTransfer,
	AIMCapabilityGetFiles,
	AIMCapabilityDirectIM,
	AIMCapabilityOther
} AIMCapabilityType;

@interface AIMCapability : NSObject {
	NSData * uuid;
}

@property (readonly) NSData * uuid;

- (id)initWithType:(AIMCapabilityType)capType;
- (id)initWithUUID:(NSData *)capUUID;
- (BOOL)isEqualToCapability:(AIMCapability *)anotherCap;
- (AIMCapabilityType)capabilityType;
+ (NSDictionary *)uuidsForCapTypes;
+ (BOOL)compareCapArray:(NSArray *)arr1 toArray:(NSArray *)arr2;
+ (TLV *)filetransferCapabilitiesBlock;

@end
