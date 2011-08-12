//
//  AIMBArtDownloadReply.h
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMBArtQueryReplyID.h"
#import "BasicStrings.h"

@interface AIMBArtDownloadReply : NSObject {
	NSString * username;
	AIMBArtQueryReplyID * replyInfo;
	UInt16 dataLen;
	NSData * assetData;
}

@property (readonly) NSString * username;
@property (readonly) AIMBArtQueryReplyID * replyInfo;
@property (readonly) UInt16 dataLen;
@property (readonly) NSData * assetData;

- (id)initWithData:(NSData *)replyData;

@end
