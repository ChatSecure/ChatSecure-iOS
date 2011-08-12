//
//  AIMICBMMessageToServer.h
//  LibOrange
//
//  Created by Alex Nichol on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMICBMCookie.h"
#import "TLV.h"
#import "BasicStrings.h"


@interface AIMICBMMessageToServer : NSObject {
    UInt16 channel;
	AIMICBMCookie * cookie;
	NSString * loginID;
	NSArray * icbmTlvs;
}

@property (readwrite) UInt16 channel;
@property (nonatomic, retain) AIMICBMCookie * cookie;
@property (nonatomic, retain) NSString * loginID;
@property (nonatomic, retain) NSArray * icbmTlvs;

- (id)initWithMessage:(NSString *)msg toUser:(NSString *)user isAutoreply:(BOOL)isAutorep;
- (id)initWithRVData:(NSData *)rvData toUser:(NSString *)user cookie:(AIMICBMCookie *)theCookie;
- (id)initWithRVDataInitProp:(NSData *)rvData toUser:(NSString *)user cookie:(AIMICBMCookie *)theCookie;
- (NSData *)encodePacket;

@end
