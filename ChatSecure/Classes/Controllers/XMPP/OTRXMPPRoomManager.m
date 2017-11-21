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
        _bookmarksModule = [[XMPPBookmarksModule alloc] initWithMode:XMPPBookmarksModePrivateXmlStorage dispatchQueue:nil];
    }
    return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    BOOL result = [super activate:aXmppStream];
    [self.mucModule activate:aXmppStream];
    [self.mucModule addDelegate:self delegateQueue:moduleQueue];
    [multicastDelegate addDelegate:self delegateQueue:moduleQueue];
    
    [self.bookmarksModule activate:self.xmppStream];
    
    //Register view for sending message queue and occupants
    [self.databaseConnection.database asyncRegisterGroupOccupantsView:nil completionBlock:nil];
    
    return result;
}

- (void) deactivate {
    [self.mucModule removeDelegate:self];
    [self.mucModule deactivate];
    [self.bookmarksModule deactivate];
    [super deactivate];
}

- (NSString *)joinRoom:(XMPPJID *)jid withNickname:(NSString *)name subject:(NSString *)subject password:(nullable NSString *)password
{
    dispatch_async(moduleQueue, ^{
        if ([subject length]) {
            [self.tempRoomSubject setObject:subject forKey:jid.bare];
        }
    });
    
    XMPPRoom *room = [self roomForJID:jid];
    NSString* accountId = self.xmppStream.tag;
    NSString *databaseRoomKey = [OTRXMPPRoom createUniqueId:accountId jid:jid.bare];
    __block NSString *nickname = name;
    
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
        
        if (!nickname) {
            OTRXMPPAccount *account = [OTRXMPPAccount fetchObjectWithUniqueID:accountId transaction:transaction];
            nickname = account.bareJID.user;
        }
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
    
    [room joinRoomUsingNickname:nickname history:historyElement password:password];
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

- (NSString *)startGroupChatWithBuddies:(NSArray<NSString *> *)buddiesArray roomJID:(XMPPJID *)roomName nickname:(NSString *)name subject:(nullable NSString *)subject
{
    if (buddiesArray.count) {
        [self performBlockAsync:^{
            [self.inviteDictionary setObject:buddiesArray forKey:roomName.bare];
        }];
    }
    [self.roomsToConfigure addObject:roomName.bare];
    XMPPConferenceBookmark *bookmark = [[XMPPConferenceBookmark alloc] initWithJID:roomName bookmarkName:subject nick:name autoJoin:YES];
    [self.bookmarksModule fetchAndPublishWithBookmarksToAdd:@[bookmark] bookmarksToRemove:nil completion:^(NSArray<id<XMPPBookmark>> * _Nullable newBookmarks, XMPPIQ * _Nullable responseIq) {
        if (newBookmarks) {
            DDLogInfo(@"Joined new room, added to merged bookmarks: %@", newBookmarks);
        }
    } completionQueue:nil];
    return [self joinRoom:roomName withNickname:name subject:subject password:nil];
}

- (void)inviteBuddies:(NSArray<NSString *> *)buddyUniqueIds toRoom:(XMPPRoom *)room {
    if (!buddyUniqueIds.count) {
        return;
    }
    NSMutableArray<XMPPJID*> *buddyJIDs = [NSMutableArray arrayWithCapacity:buddyUniqueIds.count];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        [buddyUniqueIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            OTRXMPPBuddy *buddy = [OTRXMPPBuddy fetchObjectWithUniqueID:obj transaction:transaction];
            XMPPJID *buddyJID = buddy.bareJID;
            if (buddyJID) {
                [buddyJIDs addObject:buddyJID];
            }
        }];
    }];
    // XMPPRoom.inviteUsers doesn't seem to work, so you have
    // to send an individual invitation for each person.
    [buddyJIDs enumerateObjectsUsingBlock:^(XMPPJID * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [room inviteUser:obj withMessage:nil];
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
    
    [self addRoomsToBookmarks:roomArray];
    
    [self.bookmarksModule fetchBookmarks:^(NSArray<id<XMPPBookmark>> * _Nullable bookmarks, XMPPIQ * _Nullable responseIq) {
        
    } completionQueue:nil];
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
    XMPPStream *stream = self.xmppStream;
    NSString *accountUniqueId = stream.tag;
    __block NSString *nickname = stream.myJID.user;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        OTRXMPPAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        if (account) {
            nickname = account.displayName;
        }
        buddy = [OTRXMPPBuddy fetchBuddyWithJid:fromJID accountUniqueId:accountUniqueId transaction:transaction];
    }];
    // We were invited by someone not on our roster. Shady business!
    if (!buddy) {
        DDLogWarn(@"Received room invitation from someone not on our roster! %@ %@", fromJID, message);
        return;
    }
    [self joinRoom:roomJID withNickname:nickname subject:nil password:password];
}

#pragma - mark XMPPRoomDelegate Methods

- (void) xmppRoom:(XMPPRoom *)room didFetchMembersList:(NSArray<NSXMLElement*> *)items {
    DDLogInfo(@"Fetched members list: %@", items);
    NSString *accountId = room.xmppStream.tag;
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [items enumerateObjectsUsingBlock:^(NSXMLElement *item, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *jidString = [item attributeStringValueForName:@"jid"];
            XMPPJID *jid = [XMPPJID jidWithString:jidString];
            if (!jid) { return; }
            // Make sure occupant object exists/is created
            OTRXMPPRoomOccupant *occupant = [OTRXMPPRoomOccupant occupantWithJid:jid realJID:jid roomJID:room.roomJID accountId:accountId createIfNeeded:YES transaction:transaction];
            [occupant saveWithTransaction:transaction];
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
            
            //Set Room Subject
            NSString *subject = [self.tempRoomSubject objectForKey:sender.roomJID.bare];
            if (subject) {
                [self.tempRoomSubject removeObjectForKey:sender.roomJID.bare];
                [sender changeRoomSubject:subject];
            }
        }
        
        //Invite buddies
        NSArray<NSString*> *buddyUniqueIds = [self.inviteDictionary objectForKey:sender.roomJID.bare];
        if (buddyUniqueIds) {
            [self.inviteDictionary removeObjectForKey:sender.roomJID.bare];
            [self inviteBuddies:buddyUniqueIds toRoom:sender];
        }
        
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
