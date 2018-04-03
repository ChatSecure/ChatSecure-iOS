//
//  OTRXMPPBuddyTimers.h
//  Off the Record
//
//  Created by David on 1/28/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import Foundation;

@interface OTRXMPPBuddyTimers : NSObject

@property (nonatomic, strong, readwrite, nullable) NSTimer * pausedChatStateTimer;
@property (nonatomic, strong, readwrite, nullable) NSTimer * inactiveChatStateTimer;

@end
