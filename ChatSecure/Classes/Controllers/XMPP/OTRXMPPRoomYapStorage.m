//
//  OTRXMPPRoomYapStorage.m
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPRoomYapStorage.h"
#import "OTRDatabaseManager.h"
#import "OTRAccount.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import "OTRLog.h"
#import "OTRXMPPManager_Private.h"
@import YapDatabase;
@import XMPPFramework;

@interface OTRXMPPRoomYapStorage ()

@property (nonatomic) dispatch_queue_t parentQueue;

@end

@implementation OTRXMPPRoomYapStorage

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection
{
    if (self = [self init]){
        self.databaseConnection = databaseConnection;
    }
    return self;
}

- (OTRXMPPRoomOccupant *)roomOccupantForJID:(NSString *)jid realJID:(NSString *)realJID roomJID:(NSString *)roomJID accountId:(NSString *)accountId inTransaction:(YapDatabaseReadTransaction *)transaction alwaysReturnObject:(BOOL)alwaysReturnObject
{
    __block OTRXMPPRoomOccupant *occupant = nil;
        
    OTRXMPPRoom *databaseRoom = [self fetchRoomWithXMPPRoomJID:roomJID accountId:accountId inTransaction:transaction];
    //Enumerate of room eges to occupants
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    [[transaction ext:extensionName] enumerateEdgesWithName:[OTRXMPPRoomOccupant roomEdgeName] destinationKey:databaseRoom.uniqueId collection:[OTRXMPPRoom collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        
        OTRXMPPRoomOccupant *tempOccupant = [transaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        if((realJID != nil && [tempOccupant.realJID isEqualToString:realJID]) || (jid != nil && [tempOccupant.jid isEqualToString:jid])) {
            occupant = tempOccupant;
            *stop = YES;
        }
    }];
    
    if(!occupant && alwaysReturnObject) {
        occupant = [[OTRXMPPRoomOccupant alloc] init];
        occupant.jid = jid;
        occupant.realJID = realJID;
        occupant.roomUniqueId = [OTRXMPPRoom createUniqueId:accountId jid:roomJID];
    }
    
    // Make sure we fill in the jids if we haven't got them already (note: we might well assign nil to them here, basically a no-op, but if we have them they will be set)
    if (!occupant.jid) {
        occupant.jid = jid;
    }
    if (!occupant.realJID) {
        occupant.realJID = realJID;
    }
    
    return occupant;
}

- (OTRXMPPRoom *)fetchRoomWithXMPPRoomJID:(NSString *)roomJID accountId:(NSString *)accountId inTransaction:(YapDatabaseReadTransaction *)transaction {
    return [OTRXMPPRoom fetchObjectWithUniqueID:[OTRXMPPRoom createUniqueId:accountId jid:roomJID] transaction:transaction];
}

- (BOOL)existsMessage:(XMPPMessage *)message from:(XMPPJID *)fromJID stanzaId:(nullable NSString*)stanzaId transaction:(YapDatabaseReadTransaction *)transaction
{
    NSDate *remoteTimestamp = [message delayedDeliveryDate];
    if (!remoteTimestamp)
    {
        // When the xmpp server sends us a room message, it will always timestamp delayed messages.
        // For example, when retrieving the discussion history, all messages will include the original timestamp.
        // If a message doesn't include such timestamp, then we know we're getting it in "real time".
        
        return NO;
    }
    NSString *elementID = message.elementID;
    __block BOOL result = NO;
    [transaction enumerateMessagesWithElementId:elementID originId:nil stanzaId:stanzaId block:^(id<OTRMessageProtocol> _Nonnull databaseMessage, BOOL * _Null_unspecified stop) {
        //Need to check room JID
        //So if message has same ID and same room jid that's got to be the same message, right?
        if ([databaseMessage isKindOfClass:[OTRXMPPRoomMessage class]]) {
            OTRXMPPRoomMessage *msg = (OTRXMPPRoomMessage *)databaseMessage;
            if ([msg.roomJID isEqualToString:fromJID.bare]) {
                *stop = YES;
                result = YES;
            }}
    }];
    return result;
}

- (void)insertIncomingMessage:(XMPPMessage *)message intoRoom:(XMPPRoom *)room
{
    NSString *accountId = room.xmppStream.tag;
    NSString *roomJID = room.roomJID.bare;
    XMPPJID *fromJID = [message from];
    if (!accountId || !roomJID || !fromJID) {
        return;
    }
    __block OTRXMPPRoomMessage *databaseMessage = nil;
    __block OTRXMPPRoom *databaseRoom = nil;
    __block OTRXMPPAccount *account = nil;
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        account = [OTRXMPPAccount fetchObjectWithUniqueID:accountId transaction:transaction];
        // Sends a response receipt when receiving a delivery receipt request
        [OTRXMPPRoomMessage handleDeliveryReceiptRequestWithMessage:message xmppStream:room.xmppStream];
        
        // Extract XEP-0359 stanza-id
        NSString *stanzaId = [message extractStanzaIdWithAccount:account];
        NSString *originId = message.originId;
        databaseMessage.originId = originId;
        databaseMessage.stanzaId = stanzaId;
        
        if ([self existsMessage:message from:fromJID stanzaId:stanzaId transaction:transaction]) {
            // This message already exists and shouldn't be inserted
            DDLogVerbose(@"%@: %@ - Duplicate MUC message", THIS_FILE, THIS_METHOD);
            return;
        }
        databaseRoom = [self fetchRoomWithXMPPRoomJID:roomJID accountId:accountId inTransaction:transaction];
        if(!databaseRoom) {
            databaseRoom = [[OTRXMPPRoom alloc] init];
            databaseRoom.lastRoomMessageId = @""; // Hack to make it show up in list
            databaseRoom.accountUniqueId = accountId;
            databaseRoom.jid = roomJID;
        }
        if (databaseRoom.joined &&
            ([message elementForName:@"x" xmlns:XMPPMUCUserNamespace] ||
            [message elementForName:@"x" xmlns:@"jabber:x:conference"])) {
                DDLogWarn(@"Received invitation to current room: %@", message);
                return;
        }
        
        databaseMessage = [[OTRXMPPRoomMessage alloc] init];
        databaseMessage.xmppId = [message elementID];
        databaseMessage.messageText = [message body];
        NSDate *messageDate = [message delayedDeliveryDate];
        if (!messageDate) {
            messageDate = [NSDate date];
        }
        databaseMessage.messageDate = messageDate;
        databaseMessage.senderJID = [fromJID full];
        databaseMessage.roomJID = databaseRoom.jid;
        databaseMessage.state = RoomMessageStateReceived;
        databaseMessage.roomUniqueId = databaseRoom.uniqueId;
        OTRXMPPRoomOccupant *occupant = [self roomOccupantForJID:databaseMessage.senderJID realJID:nil roomJID:databaseMessage.roomJID accountId:accountId inTransaction:transaction alwaysReturnObject:YES];
        databaseMessage.displayName = occupant.realJID;
        if (!databaseMessage.displayName) {
            databaseMessage.displayName = [fromJID bare];
        }
        
        databaseRoom.lastRoomMessageId = [databaseMessage uniqueId];
        NSString *activeThreadYapKey = [[OTRAppDelegate appDelegate] activeThreadYapKey];
        if([activeThreadYapKey isEqualToString:databaseMessage.threadId]) {
            databaseMessage.read = YES;
        } else {
            databaseMessage.read = NO;
        }
        
        [databaseRoom saveWithTransaction:transaction];
        [databaseMessage saveWithTransaction:transaction];
    } completionBlock:^{
        if(databaseMessage) {
            OTRXMPPManager *xmpp = (OTRXMPPManager*)[OTRProtocolManager.shared protocolForAccount:account];
            [xmpp.fileTransferManager createAndDownloadItemsIfNeededWithMessage:databaseMessage readConnection:OTRDatabaseManager.shared.readOnlyDatabaseConnection force:NO];
            // If delayedDeliveryDate is set we are retrieving history. Don't show
            // notifications in that case. Also, don't show notifications for archived
            // rooms.
            if (!message.delayedDeliveryDate && !databaseRoom.isArchived) {
                [[UIApplication sharedApplication] showLocalNotification:databaseMessage];
            }
        }
    }];
}

- (id <OTRMessageProtocol>)lastMessageInRoom:(XMPPRoom *)room accountKey:(NSString *)accountKey
{
    __block id<OTRMessageProtocol> message = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        OTRXMPPRoom *databaseRoom = [self fetchRoomWithXMPPRoomJID:room.roomJID.bare accountId:accountKey inTransaction:transaction];
        message = [databaseRoom lastMessageWithTransaction:transaction];
    }];
    return message;
}

//MARK: XMPPRoomStorage

- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue
{
    self.parentQueue = queue;
    return YES;
}

/**
 * Updates and returns the occupant for the given presence element.
 * If the presence type is "available", and the occupant doesn't already exist, then one should be created.
 **/
- (void)handlePresence:(XMPPPresence *)presence room:(XMPPRoom *)room {
    NSString *accountId = room.xmppStream.tag;
    XMPPJID *presenceJID = [presence from];
    NSArray *children = [presence children];
    __block XMPPJID *buddyJID = nil;
    __block NSString *buddyRole = nil;
    __block NSString *buddyAffiliation = nil;
    [children enumerateObjectsUsingBlock:^(NSXMLElement *element, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[element xmlns] containsString:XMPPMUCNamespace]) {
            NSArray *items = [element children];
            [items enumerateObjectsUsingBlock:^(NSXMLElement *item, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *jid = [item attributeStringValueForName:@"jid"];
                if ([jid length]) {
                    buddyJID = [XMPPJID jidWithString:jid];
                    buddyRole = [item attributeStringValueForName:@"role"];
                    buddyAffiliation = [item attributeStringValueForName:@"affiliation"];
                    *stop = YES;
                }
            }];
            *stop = YES;
        }
    }];
    
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {

        // Get the real JID, need to find occupant by EITHER room jid or real JID
        NSString *realJID = nil;
        if (buddyJID) {
            realJID = buddyJID.bare;
        } else {
            // Not really sure what's going on here
            realJID = [presenceJID resource];
        }
        
        OTRXMPPRoomOccupant *occupant = [self roomOccupantForJID:[presenceJID full] realJID:realJID roomJID:room.roomJID.bare accountId:accountId inTransaction:transaction alwaysReturnObject:YES];
        if ([[presence type] isEqualToString:@"unavailable"]) {
            occupant.available = NO; 
        } else {
            occupant.available = YES;
        }
        
        occupant.roomName = [presenceJID resource];
        
        // Role
        if ([buddyRole isEqualToString:@"moderator"]) {
            occupant.role = RoomOccupantRoleModerator;
        } else if ([buddyRole isEqualToString:@"participant"]) {
            occupant.role = RoomOccupantRoleParticipant;
        } else if ([buddyRole isEqualToString:@"visitor"]) {
            occupant.role = RoomOccupantRoleVisitor;
        } else {
            occupant.role = RoomOccupantRoleNone;
        }

        // Affiliation
        if ([buddyAffiliation isEqualToString:@"owner"]) {
            occupant.affiliation = RoomOccupantAffiliationOwner;
        } else if ([buddyAffiliation isEqualToString:@"admin"]) {
            occupant.affiliation = RoomOccupantAffiliationAdmin;
        } else if ([buddyAffiliation isEqualToString:@"member"]) {
            occupant.affiliation = RoomOccupantAffiliationMember;
        } else if ([buddyAffiliation isEqualToString:@"outcast"]) {
            occupant.affiliation = RoomOccupantAffiliationOutcast;
        } else {
            occupant.affiliation = RoomOccupantAffiliationNone;
        }
        [occupant saveWithTransaction:transaction];
    }];
}

/**
 * Stores or otherwise handles the given message element.
 **/
- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room {
    //DDLogVerbose(@"OTRXMPPRoomYapStorage handleIncomingMessage: %@", message);
    XMPPJID *myRoomJID = room.myRoomJID;
    XMPPJID *messageJID = [message from];
    
    if ([myRoomJID isEqualToJID:messageJID])
    {
        if (![message wasDelayed])
        {
            // Ignore - we already stored message in handleOutgoingMessage:room:
            return;
        }
    }
    
    //May need to check if the message is unique. Unsure if this is a real problem. Look at XMPPRoomCoreDataStorage.m existsMessage:
    
    [self insertIncomingMessage:message intoRoom:room];
}
- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room {
    //DDLogVerbose(@"OTRXMPPRoomYapStorage handleOutgoingMessage: %@", message);
}

/**
 * Handles leaving the room, which generally means clearing the list of occupants.
 **/
- (void)handleDidLeaveRoom:(XMPPRoom *)room {
    NSString *roomJID = room.roomJID.bare;
    NSString *accountId = room.xmppStream.tag;
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        OTRXMPPRoom *databaseRoom = [self fetchRoomWithXMPPRoomJID:roomJID accountId:accountId inTransaction:transaction];
        databaseRoom.joined = NO;
        [databaseRoom saveWithTransaction:transaction];
    }];
}

- (void)handleDidJoinRoom:(XMPPRoom *)room withNickname:(NSString *)nickname {
    NSString *roomJID = room.roomJID.bare;
    NSString *accountId = room.xmppStream.tag;
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        OTRXMPPRoom *databaseRoom = [self fetchRoomWithXMPPRoomJID:roomJID accountId:accountId inTransaction:transaction];
        
        databaseRoom.joined = YES;
        databaseRoom.ownJID = room.myRoomJID.full;
        [databaseRoom saveWithTransaction:transaction];
    }];
}



@end
