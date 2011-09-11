//
//  OTRCodec.h
//  Off the Record
//
//  Created by Chris on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRMessage.h"

@interface OTRCodec : NSObject

+(OTRMessage*) decodeMessage:(OTRMessage*)theMessage;
+(OTRMessage*) encodeMessage:(OTRMessage*)theMessage;

@end
