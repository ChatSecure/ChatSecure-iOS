//
//  AIMRateParamsReply.h
//  LibOrange
//
//  Created by Alex Nichol on 6/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMRateParams.h"
#import "AIMRateMembers.h"


@interface AIMRateParamsReply : NSObject {
	UInt16 numClasses;
	NSArray * rateParameters;
	NSArray * rateMembers;
}

@property (readonly) UInt16 numClasses;
@property (readonly) NSArray * rateParameters;
@property (readonly) NSArray * rateMembers;

- (id)initWithData:(NSData *)replyData;

@end
