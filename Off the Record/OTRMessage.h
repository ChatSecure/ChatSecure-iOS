//
//  OTRMessage.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRProtocol.h"

@interface OTRMessage : NSObject

@property (readonly, retain) NSString *message;
@property (nonatomic, retain) OTRBuddy *buddy;

- (void) send;

-(id)initWithBuddy:(OTRBuddy *)buddy message:(NSString *)message;
+(OTRMessage*)messageWithBuddy:(OTRBuddy *)buddy message:(NSString *)message;

+(void)sendMessage:(OTRMessage *)message;


@end
