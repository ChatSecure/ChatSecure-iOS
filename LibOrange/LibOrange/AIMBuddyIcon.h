//
//  AIMBuddyIcon.h
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBArtID.h"

typedef enum {
	AIMBuddyIconBMPFormat,
	AIMBuddyIconJPEGFormat,
	AIMBuddyIconGIFFormat,
	AIMBuddyIconNoImageFormat
} AIMBuddyIconFormat;

@interface AIMBuddyIcon : NSObject {
	AIMBArtID * bartItem;
	NSData * iconData;
}

@property (readonly) AIMBArtID * bartItem;
@property (readonly) NSData * iconData;

- (id)initWithBid:(AIMBArtID *)bid iconData:(NSData *)iconData;
- (AIMBuddyIconFormat)iconDataFormat;

@end
