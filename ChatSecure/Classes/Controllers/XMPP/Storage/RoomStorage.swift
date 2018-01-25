//
//  RoomStorage.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 12/7/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework
import YapDatabase

@objc public class RoomStorage: NSObject {
    private let connection: YapDatabaseConnection
    private let capabilities: XMPPCapabilities
    private let fileTransfer: FileTransferManager
    
    @objc public init(connection: YapDatabaseConnection,
                      capabilities: XMPPCapabilities,
                      fileTransfer: FileTransferManager) {
        self.connection = connection
        self.capabilities = capabilities
        self.fileTransfer = fileTransfer
    }
    
    private func existingMessage(xmppMessage: XMPPMessage,
                               delayed: Date?,
                               stanzaId: String?,
                               originId: String?,
                               transaction: YapDatabaseReadTransaction) -> OTRXMPPRoomMessage? {
        guard xmppMessage.wasDelayed == true || delayed != nil else {
            // When the xmpp server sends us a room message, it will always timestamp delayed messages.
            // For example, when retrieving the discussion history, all messages will include the original timestamp.
            // If a message doesn't include such timestamp, then we know we're getting it in "real time".
            return nil
        }
        // Only use elementId as a fallback if originId and stanzaId are missing
        var elementId: String? = nil
        if originId == nil, stanzaId == nil {
            elementId = xmppMessage.elementID
        }
        var result: OTRXMPPRoomMessage? = nil
        transaction.enumerateMessages(elementId: elementId, originId: originId, stanzaId: stanzaId) { (message, stop) in
            if let roomMessage = message as? OTRXMPPRoomMessage,
                roomMessage.senderJID == xmppMessage.from?.full {
                result = roomMessage
                stop.pointee = true
            } else {
                DDLogWarn("Found matching MUC message but intended for different recipient \(message) \(xmppMessage)")
            }
        }
        return result
    }
    
    public func insertIncoming(_ xmppMessage: XMPPMessage, delayed: Date?, into xmppRoom: XMPPRoom) {
        connection.asyncReadWrite { (transaction) in
            guard let account = xmppRoom.account(with: transaction),
            let xmppStream = xmppRoom.xmppStream else {
                return
            }
            // TODO unify this with the non-MUC receipt logic
            OTRXMPPRoomMessage.handleDeliveryReceiptRequest(message: xmppMessage, xmppStream: xmppStream)
            
            let stanzaId = xmppMessage.extractStanzaId(account: account, capabilities: self.capabilities)
            let originId = xmppMessage.originId
            
            if let duplicate = self.existingMessage(xmppMessage: xmppMessage, delayed: delayed, stanzaId: stanzaId, originId: originId, transaction: transaction) {
                DDLogVerbose("Discarding duplicate MUC message: \(duplicate) \(xmppMessage)")
                return
            }
            
            let _room = OTRXMPPRoom.fetch(xmppRoom: xmppRoom, transaction: transaction)
            if _room == nil, let yapKey = xmppRoom.roomYapKey {
                let room = OTRXMPPRoom(uniqueId: yapKey)
                room.lastRoomMessageId = "" // Hack to make it show up in list
                room.accountUniqueId = account.uniqueId
                room.jid = room.roomJID?.bare
            }
            guard let room = _room?.copyAsSelf() else {
                DDLogError("Could not find or create room for \(xmppRoom)")
                return
            }
            if room.joined,
                xmppMessage.element(forName: "x", xmlns: XMPPMUCUserNamespace) != nil,
                xmppMessage.element(forName: "x", xmlns: XMPPConferenceXmlns) != nil {
                DDLogWarn("Received invitation to current room: \(room)")
                return
            }
            
            let message = OTRXMPPRoomMessage(message: xmppMessage, delayed: delayed, room: room)
            message.originId = originId
            message.stanzaId = stanzaId
            
            if let sender = message.senderJID, let senderJid = XMPPJID(string: sender), let roomJid = room.roomJID, let occupant = OTRXMPPRoomOccupant.occupant(jid: senderJid, realJID: nil, roomJID: roomJid, accountId: account.uniqueId, createIfNeeded: false, transaction: transaction) {
                message.buddyUniqueId = occupant.buddyUniqueId
            }
            
            room.lastRoomMessageId = message.uniqueId
            room.save(with: transaction)
            message.save(with: transaction)
            
            self.fileTransfer.createAndDownloadItemsIfNeeded(message: message, force: false, transaction: transaction)
            
            if room.isArchived == false {
                UIApplication.shared.showLocalNotification(message, transaction: transaction)
            }
            MessageStorage.markAsReadIfVisible(message: message)
        }
    }
    
}


extension RoomStorage: XMPPRoomStorage {
    public func configure(withParent aParent: XMPPRoom, queue: DispatchQueue) -> Bool {
        return true
    }
    
    public func handle(_ presence: XMPPPresence, room: XMPPRoom) {
        guard let presenceJID = presence.from,
            let accountId = room.accountId,
            let mucElement = presence.element(forName: "x", xmlns: XMPPMUCUserNamespace),
            let item = mucElement.element(forName: "item")
            else {
            // DDLogWarn("Discarding MUC presence \(presence)")
            return
        }
        connection.asyncReadWrite { (transaction) in
            // Will be nil in anonymous rooms (and semi-anonymous rooms if we are not moderators)
            var buddyJID: XMPPJID? = nil
            if let buddyJidString = item.attributeStringValue(forName: "jid") {
                buddyJID = XMPPJID(string: buddyJidString)
            }
            guard let occupant = OTRXMPPRoomOccupant.occupant(jid: presenceJID, realJID: buddyJID, roomJID: room.roomJID, accountId: accountId, createIfNeeded: true, transaction: transaction)?.copyAsSelf() else {
                DDLogWarn("Could not create room occupant")
                return
            }
            let role = item.attributeStringValue(forName: "role") ?? ""
            let affiliation = item.attributeStringValue(forName: "affiliation") ?? ""
            if presence.presenceType == .unavailable {
                occupant.available = false
            } else {
                occupant.available = true
            }
            occupant.jid = presenceJID.full
            if buddyJID != nil {
                occupant.realJID = buddyJID?.bare
            }
            occupant.roomName = presenceJID.resource
            occupant.role = RoomOccupantRole(stringValue: role)
            occupant.affiliation = RoomOccupantAffiliation(stringValue: affiliation)
            occupant.save(with: transaction)
        }
    }
    
    public func handleIncomingMessage(_ message: XMPPMessage, room: XMPPRoom) {
        guard let myRoomJID = room.myRoomJID,
            let messageJID = message.from else {
                DDLogError("Discarding invalid MUC message \(message)")
                return
        }
        if myRoomJID.isEqual(to: messageJID),
           !message.wasDelayed {
            // DDLogVerbose("Discarding duplicate outgoing MUC message \(message)")
            return
        }
        insertIncoming(message, delayed: message.delayedDeliveryDate, into: room)
    }
    
    public func handleOutgoingMessage(_ message: XMPPMessage, room: XMPPRoom) {
        // DDLogVerbose("Handle outgoing group message \(message) \(room)")
    }
    
    public func handleDidLeave(_ xmppRoom: XMPPRoom) {
        connection.asyncReadWrite { (transaction) in
            guard let room = OTRXMPPRoom.fetch(xmppRoom: xmppRoom, transaction: transaction)?.copyAsSelf() else {
                return
            }
            room.joined = false
            room.save(with: transaction)
        }
    }
    
    public func handleDidJoin(_ xmppRoom: XMPPRoom, withNickname nickname: String) {
        connection.asyncReadWrite { (transaction) in
            guard let room = OTRXMPPRoom.fetch(xmppRoom: xmppRoom, transaction: transaction)?.copyAsSelf() else {
                return
            }
            room.joined = true
            room.ownJID = xmppRoom.myRoomJID?.full
            room.save(with: transaction)
        }
    }
    
    
}
