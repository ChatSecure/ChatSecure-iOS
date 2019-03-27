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
    
    // MARK: Properties
    
    private let connection: YapDatabaseConnection
    private let capabilities: XMPPCapabilities
    private let fileTransfer: FileTransferManager
    private let vCardModule: XMPPvCardTempModule
    /// This is public because of a test-related circular dependency with OTROMEMOSignalCoordinator
    public var omemoModule: OMEMOModule?
    
    // MARK: Init
    
    @objc public init(connection: YapDatabaseConnection,
                      capabilities: XMPPCapabilities,
                      fileTransfer: FileTransferManager,
                      vCardModule: XMPPvCardTempModule,
                      omemoModule: OMEMOModule? = nil) {
        self.connection = connection
        self.capabilities = capabilities
        self.fileTransfer = fileTransfer
        self.vCardModule = vCardModule
        self.omemoModule = omemoModule
    }
    
    // MARK: Public
    
    
    /// This is used in the OTRXMPPRoomManager to insert
    /// the realJID of room members/admins/etc
    @objc public func insertOccupantItems(_ items: [XMLElement],
                                        into room: XMPPRoom) {
        let occupants = items.map { (element) in
            OccupantInfo(jid: nil, presence: nil, item: element)
        }
        insertOccupants(occupants, into: room)
    }
    
    /// body param is optional and is for overriding the xmppMessage's body
    public func insertIncoming(_ xmppMessage: XMPPMessage,
                               body: String?,
                               delayed: Date?,
                               into xmppRoom: XMPPRoom,
                               preSave: MessageStorage.PreSave? = nil) {
        if xmppMessage.isUsingExplicitEncryption(namespace: .omemo),
            body == nil {
            DDLogWarn("Group OMEMO message received but couldn't decrypt body")
            return
        }
        guard let senderJID = xmppMessage.from else {
            // No sender JID?
            return
        }
        
        connection.asyncReadWrite { (transaction) in
            guard let account = xmppRoom.account(with: transaction),
            let xmppStream = xmppRoom.xmppStream else {
                return
            }
            // TODO unify this with the non-MUC receipt logic
            OTRXMPPRoomMessage.handleDeliveryReceiptRequest(message: xmppMessage, xmppStream: xmppStream)
            
            // If this is a receipt, we are done
            if xmppMessage.hasReceiptResponse {
                return
            }
            
            let stanzaId = xmppMessage.extractStanzaId(account: account, capabilities: self.capabilities)
            let originId = xmppMessage.originId
            
            if let _ = self.existingMessage(xmppMessage: xmppMessage, delayed: delayed, stanzaId: stanzaId, originId: originId, transaction: transaction) {
                // DDLogVerbose("Discarding duplicate MUC message: \(duplicate) \(xmppMessage)")
                return
            }
            
            let _room = OTRXMPPRoom.fetch(xmppRoom: xmppRoom, transaction: transaction)
            if _room == nil, let yapKey = xmppRoom.roomYapKey {
                let room = OTRXMPPRoom(uniqueId: yapKey)
                room.lastRoomMessageId = "" // Hack to make it show up in list
                room.accountUniqueId = account.uniqueId
                room.roomJID = xmppRoom.roomJID
                room.roomUserState = .invited
            }
            guard let room = _room?.copyAsSelf(),
                let roomJID = room.roomJID else {
                DDLogError("Could not find or create room for \(xmppRoom)")
                return
            }
            if xmppMessage.element(forName: "x", xmlns: XMPPMUCUserNamespace) != nil,
                xmppMessage.element(forName: "x", xmlns: XMPPConferenceXmlns) != nil {
                DDLogWarn("Received invitation to current room: \(room)")
                return
            }
            
            let message = OTRXMPPRoomMessage(message: xmppMessage, delayed: delayed, room: room, transaction: transaction)
            // override body if this was an encrypted message
            if let body = body {
                message.messageText = body
            }
            message.originId = originId
            message.stanzaId = stanzaId
            
            let occupant = OTRXMPPRoomOccupant.occupant(jid: senderJID, realJID: message.realJID, roomJID: roomJID, accountId: account.uniqueId, createIfNeeded: true, transaction: transaction)
            occupant?.save(with: transaction)
            
            room.lastRoomMessageId = message.uniqueId
            room.save(with: transaction)
            preSave?(message, transaction)
            message.save(with: transaction)
            
            self.fileTransfer.createAndDownloadItemsIfNeeded(message: message, force: false, transaction: transaction)
            
            if room.isArchived == false {
                UIApplication.shared.showLocalNotification(message, transaction: transaction)
            }
            MessageStorage.markAsReadIfVisible(message: message)
        }
    }
    
    // MARK: Private
    
    private struct OccupantInfo {
        /// JID of the occupant inside the room
        var jid: XMPPJID?
        /// optional presence information
        var presence: XMPPPresence?
        /// additional item information about occupant
        /// containing role, affiliation, public JID, etc
        var item: XMLElement?
    }
    
    private func insertOccupants(_ occupants:[OccupantInfo],
                                 into room: XMPPRoom) {
        guard let accountId = room.accountId else {
            assert(room.accountId != nil)
            DDLogError("No accountId attached to room!")
            return
        }
        
        connection.asyncReadWrite { (transaction) in
            occupants.forEach({ (occupantInfo) in
                let presenceJID = occupantInfo.jid
                let item = occupantInfo.item
                // Will be nil in anonymous rooms (and semi-anonymous rooms if we are not moderators)
                var realJID: XMPPJID? = nil
                if let buddyJidString = item?.attributeStringValue(forName: "jid") {
                    realJID = XMPPJID(string: buddyJidString)
                }
                guard let occupant = OTRXMPPRoomOccupant.occupant(jid: presenceJID, realJID: realJID, roomJID: room.roomJID, accountId: accountId, createIfNeeded: true, transaction: transaction)?.copyAsSelf() else {
                    DDLogWarn("Could not create room occupant")
                    return
                }
                if let room = OTRXMPPRoom.fetch(xmppRoom: room, transaction: transaction),
                    let presence = occupantInfo.presence,
                    let presenceJID = presence.from {
                    OTRBuddyCache.shared.setJid(presenceJID.full, online: presence.presenceType != .unavailable, in:room)
                }
                // Update their role/affiliation information
                if let role = item?.attributeStringValue(forName: "role") {
                    occupant.role = RoomOccupantRole(stringValue: role)
                }
                if let affiliation = item?.attributeStringValue(forName: "affiliation") {
                    occupant.affiliation = RoomOccupantAffiliation(stringValue: affiliation)
                }
                
                // it's best to map "real" buddies to room occupants when we can
                if let realJID = realJID?.bareJID {
                    var buddy = OTRXMPPBuddy.fetchBuddy(jid: realJID, accountUniqueId: accountId, transaction: transaction)
                    if buddy == nil {
                        // if an existing buddy is not found
                        // let's create an 'untrusted' room buddy,
                        // this facilitates vCard fetch and OMEMO key fetch
                        // this buddy is not considered on the user's roster
                        buddy = OTRXMPPBuddy(jid: realJID, accountId: accountId)
                        buddy?.trustLevel = .untrusted
                        buddy?.save(with: transaction)
                        DDLogInfo("Created non-roster buddy for room \(realJID) \(room)")
                    }
                    occupant.buddyUniqueId = buddy?.uniqueId
                    /// Fetch vCard for avatar
                    self.vCardModule.fetchvCardTemp(for: realJID, ignoreStorage: false)
                    /// Fetch DeviceIds for prepping future OMEMO sessions
                    self.omemoModule?.fetchDeviceIds(for: realJID, elementId: nil)
                }
                occupant.save(with: transaction)
            })
        }
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
    
}


// MARK: - XMPPRoomStorage
extension RoomStorage: XMPPRoomStorage {
    public func configure(withParent aParent: XMPPRoom, queue: DispatchQueue) -> Bool {
        return true
    }
    
    public func handle(_ presence: XMPPPresence, room: XMPPRoom) {
        if let item = presence.element(forName: "x", xmlns: XMPPMUCUserNamespace)?.element(forName: "item") {
            let occupant = OccupantInfo(jid: presence.from, presence: presence, item: item)
            insertOccupants([occupant], into: room)
        } else {
            DDLogError("Could not extract occupant item from presence \(presence)")
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
        insertIncoming(message, body: nil, delayed: message.delayedDeliveryDate, into: room)
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
            room.ourJID = xmppRoom.myRoomJID
            room.save(with: transaction)
        }
    }
}

// MARK: - XEP-0380: Explicit Message Encryption
// TODO: Move me somewhere else
/// XEP-0380: Explicit Message Encryption
/// https://xmpp.org/extensions/xep-0380.html
public extension XMPPMessage {
    /// XEP-0380: Explicit Message Encryption
    static let emeXmlns = "urn:xmpp:eme:0"
    
    enum EncryptionNamespace: String {
        case otr = "urn:xmpp:otr:0"
        case omemo = "eu.siacs.conversations.axolotl"
        case pgp = "urn:xmpp:openpgp:0"
    }
    
    struct ExplicitEncryption {
        var namespace: EncryptionNamespace
        var name: String?
    }
    
    func isUsingExplicitEncryption(namespace: EncryptionNamespace) -> Bool {
        return explicitMessageEncryption?.namespace == namespace
    }
    
    var explicitMessageEncryption: ExplicitEncryption? {
        guard let element = element(forName: "encryption", xmlns: XMPPMessage.emeXmlns),
        let namespaceString = element.attributeStringValue(forName: "namespace"),
            let namespace = EncryptionNamespace(rawValue: namespaceString) else {
            return nil
        }
        let name = element.attributeStringValue(forName: "name")
        return ExplicitEncryption(namespace: namespace, name: name)
    }
}
