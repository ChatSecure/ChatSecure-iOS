//
//  OTRXMPPRoomManager.m
//  ChatSecure
//
//  Created by David Chiles on 10/9/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPRoomManager.h"
@import XMPPFramework;
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRXMPPRoomYapStorage.h"
#import "OTRBuddy.h"
@import YapDatabase;
#import "OTRLog.h"


@interface OTRXMPPRoomManager () <XMPPMUCDelegate, XMPPRoomDelegate, XMPPStreamDelegate, OTRYapViewHandlerDelegateProtocol>

@property (nonatomic, strong, readonly) NSMutableDictionary<XMPPJID*,XMPPRoom*> *rooms;

@property (nonatomic, strong, readonly) XMPPMUC *mucModule;

/** This dictionary has jid as the key and array of buddy unique Ids to invite once we've joined the room*/
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSArray<NSString *> *> *inviteDictionary;

/** This dictionary is a temporary holding for setting a room subject. Once the room is created teh subject is set from this dictionary. */
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSString*> *tempRoomSubject;

/** This array is a temporary holding with rooms we should configure once connected */
@property (nonatomic, strong, readonly) NSMutableArray<NSString*> *roomsToConfigure;

@end

@implementation OTRXMPPRoomManager

- (instancetype)init {
    if (self = [super init]) {
        _mucModule = [[XMPPMUC alloc] init];
        _inviteDictionary = [[NSMutableDictionary alloc] init];
        _tempRoomSubject = [[NSMutableDictionary alloc] init];
        _roomsToConfigure = [[NSMutableArray alloc] init];
        _rooms = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    BOOL result = [super activate:aXmppStream];
    [self.mucModule activate:aXmppStream];
    [self.mucModule addDelegate:self delegateQueue:moduleQueue];
    [multicastDelegate addDelegate:self delegateQueue:moduleQueue];
    return result;
}

- (NSString *)joinRoom:(XMPPJID *)jid withNickname:(NSString *)name subject:(NSString *)subject password:(nullable NSString *)password
{
    dispatch_async(moduleQueue, ^{
        if ([subject length]) {
            [self.tempRoomSubject setObject:subject forKey:jid.bare];
        }
    });
    
    //Register view for sending message queue and occupants
    [self.databaseConnection.database asyncRegisterGroupOccupantsView:nil completionBlock:nil];
    
    
    XMPPRoom *room = [self roomForJID:jid];
    NSString* accountId = self.xmppStream.tag;
    NSString *databaseRoomKey = [OTRXMPPRoom createUniqueId:accountId jid:jid.bare];
    
    if (!room) {
        OTRXMPPRoomYapStorage *storage = [[OTRXMPPRoomYapStorage alloc] initWithDatabaseConnection:self.databaseConnection];
        room = [[XMPPRoom alloc] initWithRoomStorage:storage jid:jid];
        [self setRoom:room forJID:room.roomJID];
        [room activate:self.xmppStream];
        [room addDelegate:self delegateQueue:moduleQueue];
    }
    
    /** Create room database object */
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        OTRXMPPRoom *room = [[OTRXMPPRoom fetchObjectWithUniqueID:databaseRoomKey transaction:transaction] copy];
        if(!room) {
            room = [[OTRXMPPRoom alloc] init];
            room.lastRoomMessageId = @""; // Hack to make it show up in list
            room.accountUniqueId = accountId;
            room.jid = jid.bare;
        } else {
            // Clear out roles, we'll getpresence updates once we join
            [self clearOccupantRolesInRoom:room withTransaction:transaction];
        }
        
        //Other Room properties should be set here
        if ([subject length]) {
            room.subject = subject;
        }
        room.roomPassword = password;
        
        [room saveWithTransaction:transaction];
    }];
    
    //Get history if any
    NSXMLElement *historyElement = nil;
    OTRXMPPRoomYapStorage *storage = room.xmppRoomStorage;
    id<OTRMessageProtocol> lastMessage = [storage lastMessageInRoom:room accountKey:accountId];
    NSDate *lastMessageDate = [lastMessage messageDate];
    if (lastMessageDate) {
        //Use since as our history marker if we have a last message
        //http://xmpp.org/extensions/xep-0045.html#enter-managehistory
        NSString *dateTimeString = [lastMessageDate xmppDateTimeString];
        historyElement = [NSXMLElement elementWithName:@"history"];
        [historyElement addAttributeWithName:@"since" stringValue:dateTimeString];
    }
    
    [room joinRoomUsingNickname:name history:historyElement password:password];
    return databaseRoomKey;
}

- (void)leaveRoom:(nonnull XMPPJID *)jid
{
    XMPPRoom *room = [self roomForJID:jid];
    [room leaveRoom];
    [self removeRoomForJID:jid];
    [room removeDelegate:self];
    [room deactivate];
}

- (void)clearOccupantRolesInRoom:(OTRXMPPRoom *)room withTransaction:(YapDatabaseReadWriteTransaction * _Nonnull)transaction {
    //Enumerate of room eges to occupants
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    [[transaction ext:extensionName] enumerateEdgesWithName:[OTRXMPPRoomOccupant roomEdgeName] destinationKey:room.uniqueId collection:[OTRXMPPRoom collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        
        OTRXMPPRoomOccupant *occupant = [transaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        occupant.role = RoomOccupantRoleNone;
        [occupant saveWithTransaction:transaction];
    }];
}

- (NSString *)startGroupChatWithBuddies:(NSArray<NSString *> *)buddiesArray roomJID:(XMPPJID *)roomName nickname:(nonnull NSString *)name subject:(nullable NSString *)subject
{
    if (buddiesArray.count) {
        [self performBlockAsync:^{
            [self.inviteDictionary setObject:buddiesArray forKey:roomName.bare];
        }];
    }
    [self.roomsToConfigure addObject:roomName.bare];
    return [self joinRoom:roomName withNickname:name subject:subject password:nil];
}

- (void)inviteUser:(XMPPJID *)user toRoom:(XMPPJID *)roomJID withMessage:(NSString *)message
{
    XMPPRoom *room = [self roomForJID:roomJID];
    [room inviteUser:user withMessage:message];
}

- (OTRXMPPRoomOccupant * _Nullable) roomOccupantForJID:(NSString *)jid realJID:(NSString *)realJID inRoom:(NSString *)roomJID {
    XMPPRoom *room = [self roomForJID:[XMPPJID jidWithString:roomJID]];
    __block OTRXMPPRoomOccupant *occupant = nil;
    if (room != nil && [room.xmppRoomStorage isKindOfClass:OTRXMPPRoomYapStorage.class]) {
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            NSString *roomJID = room.roomJID.bare;
            NSString *accountId = room.xmppStream.tag;
            occupant = [(OTRXMPPRoomYapStorage*)room.xmppRoomStorage roomOccupantForJID:jid realJID:realJID roomJID:roomJID accountId:accountId inTransaction:transaction alwaysReturnObject:YES];
        }];
    }
    return occupant;
}

- (void)inviteBuddies:(NSArray<NSString *> *)buddyUniqueIds toRoom:(XMPPRoom *)room {
    if (!buddyUniqueIds.count) {
        return;
    }
    NSMutableArray<OTRXMPPBuddy*> *buddies = [NSMutableArray arrayWithCapacity:buddyUniqueIds.count];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        [buddyUniqueIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchObjectWithUniqueID:obj transaction:transaction];
            if (buddy) {
                [buddies addObject:buddy];
            }
        }];
    }];
    [buddies enumerateObjectsUsingBlock:^(OTRXMPPBuddy * _Nonnull buddy, NSUInteger idx, BOOL * _Nonnull stop) {
        [self inviteUser:buddy.bareJID toRoom:room.roomJID withMessage:nil];
    }];

}

#pragma - mark XMPPStreamDelegate Methods

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    
    //Once we've connecected and authenticated we find what room services are available
    [self.mucModule discoverServices];
    //Once we've authenitcated we need to rejoin existing rooms
    NSMutableArray <OTRXMPPRoom *>*roomArray = [[NSMutableArray alloc] init];
    __block NSString *nickname = self.xmppStream.myJID.user;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        OTRXMPPAccount *account = [OTRXMPPAccount accountForStream:sender transaction:transaction];
        if (account) {
            nickname = account.displayName;
        }
        [transaction enumerateKeysAndObjectsInCollection:[OTRXMPPRoom collection] usingBlock:^(NSString * _Nonnull key, id  _Nonnull object, BOOL * _Nonnull stop) {
            
            if ([object isKindOfClass:[OTRXMPPRoom class]]) {
                OTRXMPPRoom *room = (OTRXMPPRoom *)object;
                if ([room.jid length]) {
                    [roomArray addObject:room];
                }
            }
            
        } withFilter:^BOOL(NSString * _Nonnull key) {
            //OTRXMPPRoom is saved with the jid and account id as part of the key
            if ([key containsString:sender.tag]) {
                return YES;
            }
            return NO;
        }];
    }];
    [roomArray enumerateObjectsUsingBlock:^(OTRXMPPRoom * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self joinRoom:[XMPPJID jidWithString:obj.jid] withNickname:nickname subject:obj.subject password:obj.roomPassword];
    }];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    //Check id and mark as needs sending
    
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    //Check id and mark as sent
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    XMPPJID *from = [message from];
    //Check that this is a message for one of our rooms
    if([message isGroupChatMessageWithSubject] && [self roomForJID:from] != nil) {
        
        NSString *subject = [message subject];
        
        NSString *databaseRoomKey = [OTRXMPPRoom createUniqueId:self.xmppStream.tag jid:from.bare];
        
        [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            OTRXMPPRoom *room = [OTRXMPPRoom fetchObjectWithUniqueID:databaseRoomKey transaction:transaction];
            room.subject = subject;
            [room saveWithTransaction:transaction];
        }];
        
    }
    
    // Handle group chat message receipts
    [OTRXMPPRoomMessage handleDeliveryReceiptResponseWithMessage:message writeConnection:self.databaseConnection];
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
    // We must check if we trust the person who invited us
    // because some servers will send you invites from anyone
    // We should probably move some of this code upstream into XMPPFramework
    
    // Since XMPP is super great, there are (at least) two ways to receive a room invite.

    // Examples from XEP-0045:
    // Example 124. Room Sends Invitation to New Member:
    //
    // <message from='darkcave@chat.shakespeare.lit' to='hecate@shakespeare.lit'>
    //   <x xmlns='http://jabber.org/protocol/muc#user'>
    //     <invite from='bard@shakespeare.lit'/>
    //     <password>cauldronburn</password>
    //   </x>
    // </message>
    //
    
    // Examples from XEP-0249:
    //
    //
    // Example 1. A direct invitation
    //
    // <message from='crone1@shakespeare.lit/desktop' to='hecate@shakespeare.lit'>
    //   <x xmlns='jabber:x:conference'
    //      jid='darkcave@macbeth.shakespeare.lit'
    //      password='cauldronburn'
    //      reason='Hey Hecate, this is the place for all good witches!'/>
    // </message>
    
    XMPPJID *fromJID = nil;
    NSString *password = nil;
    
    NSXMLElement * roomInvite = [message elementForName:@"x" xmlns:XMPPMUCUserNamespace];
    NSXMLElement * directInvite = [message elementForName:@"x" xmlns:@"jabber:x:conference"];
    if (roomInvite) {
        // XEP-0045
        NSXMLElement * invite  = [roomInvite elementForName:@"invite"];
        fromJID = [XMPPJID jidWithString:[invite attributeStringValueForName:@"from"]];
        password = [roomInvite elementForName:@"password"].stringValue;
    } else if (directInvite) {
        // XEP-0249
        fromJID = [message from];
        password = [directInvite attributeStringValueForName:@"password"];
    }
    if (!fromJID) {
        DDLogWarn(@"Could not parse fromJID from room invite: %@", message);
        return;
    }
    __block OTRXMPPBuddy *buddy = nil;
    NSString *fromJidString = [fromJID bare];
    XMPPStream *stream = self.xmppStream;
    NSString *accountUniqueId = stream.tag;
    __block NSString *nickname = stream.myJID.user;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        OTRXMPPAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        if (account) {
            nickname = account.displayName;
        }
        buddy = [OTRXMPPBuddy fetchBuddyWithUsername:fromJidString withAccountUniqueId:accountUniqueId transaction:transaction];
    }];
    // We were invited by someone not on our roster. Shady business!
    if (!buddy) {
        DDLogWarn(@"Received room invitation from someone not on our roster! %@ %@", fromJID, message);
        return;
    }
    [self joinRoom:roomJID withNickname:nickname subject:nil password:password];
}

#pragma - mark XMPPRoomDelegate Methods

- (void) xmppRoom:(XMPPRoom *)room didFetchMembersList:(NSArray *)items {
    DDLogInfo(@"Fetched members list: %@", items);
    OTRXMPPRoomYapStorage *storage = room.xmppRoomStorage;
    
    NSString *accountId = room.xmppStream.tag;
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {

        [items enumerateObjectsUsingBlock:^(NSXMLElement *item, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *jid = [item attributeStringValueForName:@"jid"];
            if ([jid length]) {
                // Make sure occupant object exists/is created
                OTRXMPPRoomOccupant *occupant = [storage roomOccupantForJID:nil realJID:jid roomJID:room.roomJID.bare accountId:accountId inTransaction:transaction alwaysReturnObject:NO];
                if(!occupant) {
                    occupant = [[OTRXMPPRoomOccupant alloc] init];
                    occupant.jid = nil;
                    occupant.realJID = jid;
                    occupant.roomUniqueId = [OTRXMPPRoom createUniqueId:accountId jid:room.roomJID.bare];
                    [occupant saveWithTransaction:transaction];
                }
            }
        }];
    }];
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    [self performBlockAsync:^{
        //Configure room if we are the creator
        if ([self.roomsToConfigure containsObject:sender.roomJID.bare]) {
            [self.roomsToConfigure removeObject:sender.roomJID.bare];
            [sender configureRoomUsingOptions:[[self class] defaultRoomConfiguration]];
        }
        
        //Set Room Subject
        NSString *subject = [self.tempRoomSubject objectForKey:sender.roomJID.bare];
        if (subject) {
            [self.tempRoomSubject removeObjectForKey:sender.roomJID.bare];
            [sender changeRoomSubject:subject];
        }
        
        //Invite buddies
        NSArray<NSString*> *buddyUniqueIds = [self.inviteDictionary objectForKey:sender.roomJID.bare];
        [self.inviteDictionary removeObjectForKey:sender.roomJID.bare];
        [self inviteBuddies:buddyUniqueIds toRoom:sender];
        
        //Fetch member list
        [sender fetchMembersList];
    }];
}

- (void)xmppRoomDidLeave:(XMPPRoom *)sender {
    NSString *databaseRoomKey = [OTRXMPPRoom createUniqueId:self.xmppStream.tag jid:[sender.roomJID bare]];
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        OTRXMPPRoom *room = [OTRXMPPRoom fetchObjectWithUniqueID:databaseRoomKey transaction:transaction];
        if (room) {
            [self clearOccupantRolesInRoom:room withTransaction:transaction];
        }
    }];
}

#pragma mark - Utility

- (void) removeRoomForJID:(nonnull XMPPJID*)jid {
    NSParameterAssert(jid != nil);
    if (!jid) { return; }
    [self performBlockAsync:^{
        [self.rooms removeObjectForKey:jid.bareJID];
    }];
}

- (void) setRoom:(nonnull XMPPRoom*)room forJID:(nonnull XMPPJID*)jid {
    NSParameterAssert(room != nil);
    NSParameterAssert(jid != nil);
    if (!room || !jid) {
        return;
    }
    [self performBlockAsync:^{
        [self.rooms setObject:room forKey:jid.bareJID];
    }];
}

- (nullable XMPPRoom*) roomForJID:(nonnull XMPPJID*)jid {
    NSParameterAssert(jid != nil);
    if (!jid) { return nil; }
    __block XMPPRoom *room = nil;
    [self performBlock:^{
        room = [self.rooms objectForKey:jid.bareJID];
    }];
    return room;
}

/** Executes block synchronously on moduleQueue */
- (void) performBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
}

/** Executes block asynchronously on moduleQueue */
- (void) performBlockAsync:(dispatch_block_t)block {
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

#pragma - mark Class Methods

+ (NSXMLElement *)defaultRoomConfiguration
{
    NSXMLElement *form = [[NSXMLElement alloc] initWithName:@"x" xmlns:@"jabber:x:data"];

    NSXMLElement *formTypeField = [[NSXMLElement alloc] initWithName:@"field"];
    [formTypeField addAttributeWithName:@"var" stringValue:@"FORM_TYPE"];
    [formTypeField addChild:[[NSXMLElement alloc] initWithName:@"value" stringValue:@"http://jabber.org/protocol/muc#roomconfig"]];

    NSXMLElement *publicField = [[NSXMLElement alloc] initWithName:@"field"];
    [publicField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_publicroom"];
    [publicField addChild:[[NSXMLElement alloc] initWithName:@"value" numberValue:@(0)]];
    
    NSXMLElement *persistentField = [[NSXMLElement alloc] initWithName:@"field"];
    [persistentField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];
    [persistentField addChild:[[NSXMLElement alloc] initWithName:@"value" numberValue:@(1)]];
    
    NSXMLElement *whoisField = [[NSXMLElement alloc] initWithName:@"field"];
    [whoisField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_whois"];
    [whoisField addChild:[[NSXMLElement alloc] initWithName:@"value" stringValue:@"anyone"]];

    NSXMLElement *membersOnlyField = [[NSXMLElement alloc] initWithName:@"field"];
    [membersOnlyField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_membersonly"];
    [membersOnlyField addChild:[[NSXMLElement alloc] initWithName:@"value" numberValue:@(1)]];

    NSXMLElement *getMemberListField = [[NSXMLElement alloc] initWithName:@"field"];
    [getMemberListField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_getmemberlist"];
    [getMemberListField addChild:[[NSXMLElement alloc] initWithName:@"value" stringValue:@"moderator"]];
    [getMemberListField addChild:[[NSXMLElement alloc] initWithName:@"value" stringValue:@"participant"]];

    NSXMLElement *presenceBroadcastField = [[NSXMLElement alloc] initWithName:@"field"];
    [presenceBroadcastField addAttributeWithName:@"var" stringValue:@"muc#roomconfig_presencebroadcast"];
    [presenceBroadcastField addChild:[[NSXMLElement alloc] initWithName:@"value" stringValue:@"moderator"]];
    [presenceBroadcastField addChild:[[NSXMLElement alloc] initWithName:@"value" stringValue:@"participant"]];

    [form addChild:formTypeField];
    [form addChild:publicField];
    [form addChild:persistentField];
    [form addChild:whoisField];
    [form addChild:membersOnlyField];
    [form addChild:getMemberListField];
    [form addChild:presenceBroadcastField];
    
    return form;
}

@end

@implementation XMPPRoom(RoomManager)
- (void) sendRoomMessage:(OTRXMPPRoomMessage *)roomMessage {
    NSParameterAssert(roomMessage);
    if (!roomMessage) { return; }
    NSString *elementId = roomMessage.xmppId;
    if (!elementId.length) {
        elementId = roomMessage.uniqueId;
    }
    NSXMLElement *body = [NSXMLElement elementWithName:@"body" stringValue:roomMessage.text];
    // type=groupchat and to=room.full are set inside XMPPRoom.sendMessage
    XMPPMessage *message = [XMPPMessage messageWithType:nil elementID:roomMessage.xmppId child:body];
    [message addReceiptRequest];
    [self sendMessage:message];
}
@end
