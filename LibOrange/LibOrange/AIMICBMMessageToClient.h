//
//  AIMICBMMessageToClient.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNAC.h"
#import "TLV.h"
#import "AIMNickWInfo.h"
#import "AIMICBMCookie.h"


@interface AIMICBMMessageToClient : NSObject <OSCARPacket> {
	AIMICBMCookie * cookie;
	AIMNickWInfo * nickInfo;
	NSArray * icbmTlvs;
}

@property (readonly) AIMICBMCookie * cookie;
@property (readonly) UInt16 channel;
@property (readonly) AIMNickWInfo * nickInfo;
@property (readonly) NSArray * icbmTlvs;

- (NSString *)extractMessageContents;
- (BOOL)isAutoResponse;

@end
