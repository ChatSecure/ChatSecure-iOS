//
//  OTRCodec.h
//  Off the Record
//
//  Created by Chris on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRCodec : NSObject

-(id)initWithAccountName:(NSString*)accountName;

@property (nonatomic, retain) NSString* accountName;

//-(NSString*) decodeMessage:(NSString*) message fromUser:(NSString*)friendAccount;
//-(NSString*) encodeMessage:(NSString*) message toUser:(NSString*)recipientAccount;
//+(void)sendMessage:(NSString*)message toUser:(NSString*)recipient withDelay:(float)delay;

-(NSDictionary*) decodeMessage:(NSDictionary*)messageInfo;
-(NSDictionary*) encodeMessage:(NSDictionary*)messageInfo;

+(void)sendMessage:(NSDictionary*)messageInfo;
+(NSDictionary*)messageWithSender:(NSString*)sender recipient:(NSString*)recipient message:(NSString*)message protocol:(NSString*)protocol;

+(void)printDebugMessageInfo:(NSDictionary*)messageInfo;

@end
