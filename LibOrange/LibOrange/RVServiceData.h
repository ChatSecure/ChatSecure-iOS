//
//  RVServiceData.h
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "flipbit.h"


@interface RVServiceData : NSObject <OSCARPacket> {
	UInt16 multipleFilesFlag;
	UInt16 totalFileCount;
	UInt32 totalBytes;
	NSString * fileName;
}

@property (readwrite) UInt16 multipleFilesFlag;
@property (readwrite) UInt16 totalFileCount;
@property (readwrite) UInt32 totalBytes;
@property (nonatomic, retain) NSString * fileName; 

@end
