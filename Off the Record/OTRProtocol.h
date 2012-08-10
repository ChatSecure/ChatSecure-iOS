//
//  OTRProtocol.h
//  Off the Record
//
//  Created by Chris Ballinger on 6/25/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRAccount.h"

@class OTRMessage, OTRBuddy;

@protocol OTRProtocol <NSObject>

@property (nonatomic, strong) OTRAccount * account;
@property (nonatomic, strong) NSMutableDictionary * protocolBuddyList;

- (void) sendMessage:(OTRMessage*)message;
- (NSArray*) buddyList;
- (void) connectWithPassword:(NSString *)password;
- (void) disconnect;

@end