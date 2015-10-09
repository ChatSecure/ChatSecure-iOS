//
//  OTRXMPPRoomYapStorage.m
//  ChatSecure
//
//  Created by David Chiles on 10/7/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPRoomYapStorage.h"
#import <ChatSecureCore/OTRDatabaseManager.h>
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import <YapDatabase/YapDatabaseRelationship.h>
#import <ChatSecureCore/OTRAccount.h>
#import "NSXMLElement+XEP_0203.h"

@interface OTRXMPPRoomYapStorage ()

@property (nonatomic) dispatch_queue_t parentQueue;
@property (nonatomic, strong) OTRXMPPRoom *room;

@end

@implementation OTRXMPPRoomYapStorage

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection
{
    if (self = [self init]){
        self.databaseConnection = databaseConnection;
    }
    return self;
}

- (OTRXMPPRoomOccupant *)roomOccupantForJID:(NSString *)jid
{
    __block OTRXMPPRoomOccupant *occupant = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        //Enumerate of room eges to occupants
        [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:[OTRXMPPRoomOccupant roomEdgeName] destinationKey:self.room.uniqueId collection:[OTRXMPPRoom collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
            
            OTRXMPPRoomOccupant *tempOccupant = [transaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
            if([tempOccupant.jid isEqualToString:jid]) {
                
                occupant = tempOccupant;
                *stop = YES;
            }
        }];
        
    }];
    return occupant;
}

- (void)insertMessage:(XMPPMessage *)message outgoing:(BOOL)outgoing
{
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        OTRXMPPRoomMessage *databaseMessage = [[OTRXMPPRoomMessage alloc] init];
        databaseMessage.text = [message body];
        databaseMessage.date = [message delayedDeliveryDate];
        if (!databaseMessage.date) {
            databaseMessage.date = [NSDate date];
        }
        databaseMessage.senderJID = [[message from] bare];
        databaseMessage.roomJID = self.room.jid;
        databaseMessage.incoming = !outgoing;
        databaseMessage.roomUniqueId = self.room.uniqueId;
        
        [databaseMessage saveWithTransaction:transaction];
    }];
}

//MARK: XMPPRoomStorage

- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue
{
    self.parentQueue = queue;
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        self.room = [OTRXMPPRoom fetchObjectWithUniqueID:aParent.roomJID.bare transaction:transaction];
        if(!self.room) {
            self.room = [[OTRXMPPRoom alloc] initWithUniqueId:aParent.roomJID.bare];
        }
        
        //Other Room properties should be set here
        
        [self.room saveWithTransaction:transaction];
    }];
    
    return YES;
}

/**
 * Updates and returns the occupant for the given presence element.
 * If the presence type is "available", and the occupant doesn't already exist, then one should be created.
 **/
- (void)handlePresence:(XMPPPresence *)presence room:(XMPPRoom *)room {
    
    XMPPJID *presenceJID = [presence from];
    OTRXMPPRoomOccupant *occupant = [self roomOccupantForJID:presenceJID.bare];
    if ([[presence type] isEqualToString:@"unavailable"]) {
        occupant.available = NO;
    } else {
        occupant.available = YES;
    }
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [occupant saveWithTransaction:transaction];
    }];
}

/**
 * Stores or otherwise handles the given message element.
 **/
- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room {
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
    
    //May need to check if the message is unique. Unser if this is a real problem. Look at XMPPRoomCoreDataStorage.m existsMessage:
    [self insertMessage:message outgoing:NO];
}
- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room {
    
}

/**
 * Handles leaving the room, which generally means clearing the list of occupants.
 **/
- (void)handleDidLeaveRoom:(XMPPRoom *)room {
    
}



@end
