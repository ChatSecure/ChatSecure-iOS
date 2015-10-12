//
//  OTRXMPPRoomManager.m
//  ChatSecure
//
//  Created by David Chiles on 10/9/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPRoomManager.h"
#import "XMPP.h"
#import "NSXMLElement+XMPP.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "YapDatabase.h"
#import "OTRXMPPRoomYapStorage.h"
#import "XMPPIDTracker.h"

@interface OTRXMPPRoomManager () <XMPPMUCDelegate, XMPPRoomDelegate, XMPPStreamDelegate>

@property (nonatomic, strong) NSMutableDictionary *rooms;

@property (nonatomic, strong) XMPPMUC *mucModule;
@property (nonatomic, strong) XMPPIDTracker *iqTracker;

@end

@implementation OTRXMPPRoomManager

- (instancetype)init {
    if (self = [super init]) {
        self.mucModule = [[XMPPMUC alloc] init];
    }
    return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    BOOL result = [super activate:aXmppStream];
    [self.mucModule activate:aXmppStream];
    [self.mucModule addDelegate:self delegateQueue:moduleQueue];
    self.iqTracker = [[XMPPIDTracker alloc] initWithStream:aXmppStream dispatchQueue:moduleQueue];
    return result;
}

- (void)joinRoom:(XMPPJID *)jid withNickname:(NSString *)name
{
    XMPPRoom *room = [self.rooms objectForKey:jid.bare];
    if (!room) {
        OTRXMPPRoomYapStorage *storage = [[OTRXMPPRoomYapStorage alloc] initWithDatabaseConnection:self.databaseConnection];
        XMPPRoom *room = [[XMPPRoom alloc] initWithRoomStorage:storage jid:jid];
        [room activate:self.xmppStream];
        @synchronized(self.rooms) {
            [self.rooms setObject:room forKey:room.roomJID.bare];
        }
    }
    
    [room joinRoomUsingNickname:name history:nil];
}

- (NSMutableDictionary *)rooms {
    if (!_rooms) {
        _rooms = [[NSMutableDictionary alloc] init];
    }
    return _rooms;
}

#pragma - mark XMPPStreamDelegate Methods

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    
    //Once we've connecected and authenticated we find what room services are available
    [self.mucModule discoverServices];
}

#pragma - mark XMPPMUCDelegate Methods

- (void)xmppMUC:(XMPPMUC *)sender didDiscoverServices:(NSArray *)services
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[services count]];
    [services enumerateObjectsUsingBlock:^(NSXMLElement   * _Nonnull element, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *jid = [element attributeStringValueForName:@"jid"];
        if ([jid length] && [jid containsString:@"conference"]) {
            [array addObject:jid];
            //TODO instead of just checking if it's a confernce room we need to preform a iq 'get' to see it's capabilities.
            
        }
        
    }];
    _conferenceServicesJID = array;
}

- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitation:(XMPPMessage *)message
{
    OTRXMPPRoomInvitation *invite = [[OTRXMPPRoomInvitation alloc] init];
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [invite saveWithTransaction:transaction];
    }];
}

@end
