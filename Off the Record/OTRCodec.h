//
//  OTRCodec.h
//  Off the Record
//
//  Created by Chris on 8/17/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRMessage.h"
#import "OTRKit.h"

@interface OTRCodec : NSObject

+(OTRMessage*) decodeMessage:(OTRMessage*)theMessage;
+(OTRMessage*) encodeMessage:(OTRMessage*)theMessage;

@end
