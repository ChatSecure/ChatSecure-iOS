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
#import "OTRBuddy.h"

@interface OTRXMPPRoomManager () <XMPPMUCDelegate, XMPPRoomDelegate, XMPPStreamDelegate>

@property (nonatomic, strong) NSMutableDictionary *rooms;

@property (nonatomic, strong) XMPPMUC *mucModule;
@property (nonatomic, strong) XMPPIDTracker *iqTracker;

/** This dictionary has jid as the key and array of buddy unique Ids to invite once we've joined the room*/
@property (nonnull, strong) NSMutableDictionary *inviteDictionary;


@end

@implementation OTRXMPPRoomManager

- (instancetype)init {
    if (self = [super init]) {
        self.mucModule = [[XMPPMUC alloc] init];
        self.inviteDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    BOOL result = [super activate:aXmppStream];
    [self.mucModule activate:aXmppStream];
    [self.mucModule addDelegate:self delegateQueue:moduleQueue];
    [multicastDelegate addDelegate:self delegateQueue:moduleQueue];
    self.iqTracker = [[XMPPIDTracker alloc] initWithStream:aXmppStream dispatchQueue:moduleQueue];
    return result;
}

- (NSString *)joinRoom:(XMPPJID *)jid withNickname:(NSString *)name
{
    XMPPRoom *room = [self.rooms objectForKey:jid.bare];
    if (!room) {
        OTRXMPPRoomYapStorage *storage = [[OTRXMPPRoomYapStorage alloc] initWithDatabaseConnection:self.databaseConnection];
        XMPPRoom *room = [[XMPPRoom alloc] initWithRoomStorage:storage jid:jid];
        @synchronized(self.rooms) {
            [self.rooms setObject:room forKey:room.roomJID.bare];
        }
        [room activate:self.xmppStream];
        [room addDelegate:self delegateQueue:moduleQueue];
        [room joinRoomUsingNickname:name history:nil];
    }
    
    [room joinRoomUsingNickname:name history:nil];
    return [OTRXMPPRoom createUniqueId:self.xmppStream.tag jid:jid.bare];
}

- (NSString *)startGroupChatWithBuddies:(NSArray<NSString *> *)buddiesArray roomJID:(XMPPJID *)roomName nickname:(nonnull NSString *)name
{
    dispatch_async(moduleQueue, ^{
        if ([buddiesArray count]) {
            [self.inviteDictionary setObject:buddiesArray forKey:roomName.bare];
        }
    });
    
    return [self joinRoom:roomName withNickname:name];
}

- (void)inviteUser:(NSString *)user toRoom:(NSString *)roomJID withMessage:(NSString *)message
{
    XMPPRoom *room = [self.rooms objectForKey:roomJID];
    [room inviteUser:[XMPPJID jidWithString:user] withMessage:message];
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
            //TODO instead of just checking if it has the word 'confernce' in the name we need to preform a iq 'get' to see it's capabilities.
            
        }
        
    }];
    _conferenceServicesJID = array;
}

- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitation:(XMPPMessage *)message
{
    OTRXMPPRoomInvitation *invite = [[OTRXMPPRoomInvitation alloc] init];
    invite.roomJID = roomJID.bare;
    invite.message = [message body];
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [invite saveWithTransaction:transaction];
    }];
}

#pragma - mark XMPPRoomDelegate Methods

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    
    [sender configureRoomUsingOptions:[[self class] defaultRoomConfiguration]];
    
    //Invite other buddies waiting
    dispatch_async(moduleQueue, ^{
        NSArray *arary = [self.inviteDictionary objectForKey:sender.roomJID.bare];
        if ([arary count]) {
            [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                [arary enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:obj transaction:transaction];
                    if (buddy) {
                        [self inviteUser:buddy.username toRoom:sender.roomJID.bare withMessage:nil];
                    }
                }];
            }];
        }
    });
    
}

#pragma - mark Class Methods

+ (NSXMLElement *)defaultRoomConfiguration
{
    NSXMLElement *form = [[NSXMLElement alloc] initWithName:@"x" xmlns:@"jabber:x:data"];
    [form addAttributeWithName:@"typ" stringValue:@"form"];
    
    NSXMLElement *publicField = [[NSXMLElement alloc] initWithName:@"field"];
    [publicField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_publicroom"];
    [publicField addChild:[[NSXMLElement alloc] initWithName:@"value" numberValue:@(0)]];
    
    NSXMLElement *persistentField = [[NSXMLElement alloc] initWithName:@"field"];
    [publicField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];
    [publicField addChild:[[NSXMLElement alloc] initWithName:@"value" numberValue:@(1)]];
    
    NSXMLElement *whoisField = [[NSXMLElement alloc] initWithName:@"field"];
    [publicField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];
    [publicField addChild:[[NSXMLElement alloc] initWithName:@"value" stringValue:@"anyone"]];
    
    [form addChild:publicField];
    [form addChild:persistentField];
    [form addChild:whoisField];
    
    return form;
}
@end
