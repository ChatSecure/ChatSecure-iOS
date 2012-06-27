//
//  OTRProtocol.h
//  Off the Record
//
//  Created by Chris Ballinger on 6/25/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#define kOTRProtocolTypeXMPP @"xmpp"
#define kOTRProtocolTypeAIM @"prpl-oscar"

@class OTRMessage, OTRBuddy;

@protocol OTRProtocol <NSObject>

@property (nonatomic, strong) id account;
@property (nonatomic, strong) NSMutableDictionary * protocolBuddyList;

- (void) sendMessage:(OTRMessage*)message;
- (NSArray*) buddyList;

@end