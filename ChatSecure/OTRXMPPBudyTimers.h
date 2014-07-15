//
//  OTRXMPPBudyTimers.h
//  Off the Record
//
//  Created by David on 1/28/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRXMPPBudyTimers : NSObject

@property (nonatomic, strong) NSTimer * pausedChatStateTimer;
@property (nonatomic, strong) NSTimer * inactiveChatStateTimer;

@end
