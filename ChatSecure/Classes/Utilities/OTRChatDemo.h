//
//  OTRChatDemo.h
//  Off the Record
//
//  Created by David Chiles on 7/8/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;

@interface OTRChatDemo : NSObject

+ (void)loadDemoChatInDatabase;
+ (void)loadPerformanceTestChatsInDatabase;
+ (void)addDummyMessagesForExistingAccount:(NSString*)accountJid toFromBuddy:(NSString*)buddyJid count:(int)count;
    
@end
