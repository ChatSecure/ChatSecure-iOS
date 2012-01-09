//
//  OTRMessage.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRMessage : NSObject

@property (readonly, retain) NSString *sender;
@property (readonly, retain) NSString *recipient;
@property (readonly, retain) NSString *message;
@property (readonly, retain) NSString *protocol;

-(id)initWithSender:(NSString*)theSender recipient:(NSString*)theRecipient message:(NSString*)theMessage protocol:(NSString*)theProtocol;
+(OTRMessage*)messageWithSender:(NSString*)sender recipient:(NSString*)recipient message:(NSString*)message protocol:(NSString*)protocol;

+(void)sendMessage:(OTRMessage *)message;
+(void)printDebugMessageInfo:(OTRMessage*)messageInfo;


@end
