//
//  MessageStorage.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 11/21/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework
import CocoaLumberjack


@objc public class MessageStorage: XMPPModule {
    /// This gets called before a message is saved, if additional processing needs to be done elsewhere
    public typealias PreSave = (_ message: OTRBaseMessage, _ transaction: YapDatabaseReadWriteTransaction) -> Void

    // MARK: Properties
    private let connection: YapDatabaseConnection
    
    /// Capabilities must be activated elsewhere
    private let capabilities: XMPPCapabilities
    private let carbons: XMPPMessageCarbons
    private let archiving: XMPPMessageArchiveManagement
    private let fileTransfer: FileTransferManager

    // MARK: Init
    deinit {
        self.carbons.removeDelegate(self)
        self.archiving.removeDelegate(self)
    }
    
    /// Capabilities must be activated elsewhere
    @objc public init(connection: YapDatabaseConnection,
                      capabilities: XMPPCapabilities,
                      fileTransfer: FileTransferManager,
                      dispatchQueue: DispatchQueue? = nil) {
        self.connection = connection
        self.capabilities = capabilities
        self.carbons = XMPPMessageCarbons(dispatchQueue: dispatchQueue)
        self.archiving = XMPPMessageArchiveManagement(dispatchQueue: dispatchQueue)
        self.archiving.resultAutomaticPagingPageSize = NSNotFound
        self.fileTransfer = fileTransfer
        super.init(dispatchQueue: dispatchQueue)
        self.carbons.addDelegate(self, delegateQueue: self.moduleQueue)
        self.archiving.addDelegate(self, delegateQueue: self.moduleQueue)
    }
    
    // MARK: XMPPModule overrides
    
    @discardableResult override public func activate(_ xmppStream: XMPPStream) -> Bool {
        guard super.activate(xmppStream),
            carbons.activate(xmppStream),
            archiving.activate(xmppStream)
            else {
            return false
        }
        return true
    }
    
    public override func deactivate() {
        carbons.deactivate()
        archiving.deactivate()
        super.deactivate()
    }
    
    // MARK: Private
    
    /// Updates chat state for buddy
    private func handleChatState(message: XMPPMessage, buddy: OTRXMPPBuddy) {
        let chatState = OTRChatState.chatState(from: message.chatState)
        OTRBuddyCache.shared.setChatState(chatState, for: buddy)
    }
    
    /// Marks a previously sent outgoing message as delivered.
    private func handleDeliveryResponse(message: XMPPMessage, transaction: YapDatabaseReadWriteTransaction) {
        guard message.hasReceiptResponse,
            !message.isErrorMessage,
            let responseId = message.receiptResponseID else {
                return
        }
        var _deliveredMessage: OTROutgoingMessage? = nil
        transaction.enumerateMessages(elementId: responseId, originId: responseId, stanzaId: nil) { (message, stop) in
            if let message = message as? OTROutgoingMessage {
                _deliveredMessage = message
                stop.pointee = true
            }
        }
        if _deliveredMessage == nil {
            DDLogVerbose("Outgoing message not found for receipt: \(message)")
            // This can happen with MAM + OMEMO where the decryption
            // for the OMEMO message makes it come in after the receipt
            // To solve this, we need to make a placeholder message...
            
            // TODO.......
        }
        guard let deliveredMessage = _deliveredMessage,
            deliveredMessage.isDelivered == false,
            deliveredMessage.dateDelivered == nil else {
            return
        }
        if let deliveredMessage = deliveredMessage.copyAsSelf() {
            deliveredMessage.isDelivered = true
            deliveredMessage.dateDelivered = Date()
            deliveredMessage.save(with: transaction)
        }        
    }
    
    /// It is a violation of the XMPP spec to discard messages with duplicate stanza elementIds. We must use XEP-0359 stanza-id only.
    private func isDuplicate(message: OTRBaseMessage, transaction: YapDatabaseReadTransaction) -> Bool {
        var result = false
        let buddyUniqueId = message.buddyUniqueId
        let oid = message.originId
        let sid = message.stanzaId
        if oid == nil, sid == nil {
            return false
        }
        transaction.enumerateMessages(elementId: nil, originId: oid, stanzaId: sid) { (message, stop) in
            if message.threadId == buddyUniqueId {
                result = true
                stop.pointee = true
            }
        }
        return result
    }
    
    /// Handles both MAM and Carbons
    public func handleForwardedMessage(_ xmppMessage: XMPPMessage,
                                        forJID: XMPPJID,
                                        body: String?,
                                        accountId: String,
                                        delayed: Date?,
                                        isIncoming: Bool,
                                        preSave: PreSave? = nil ) {
        guard !xmppMessage.isErrorMessage else {
            DDLogWarn("Discarding forwarded message: \(xmppMessage)")
            return
        }
        // Ignore OTR text
        if let messageBody = xmppMessage.body, messageBody.isOtrText {
            return
        }

        connection.asyncReadWrite { (transaction) in
            guard let account = OTRXMPPAccount.fetchObject(withUniqueID: accountId, transaction: transaction),
                let buddy = OTRXMPPBuddy.fetchBuddy(jid: forJID, accountUniqueId: accountId, transaction: transaction) else {
                    return
            }
            var _message: OTRBaseMessage? = nil
            
            if isIncoming {
                self.handleDeliveryResponse(message: xmppMessage, transaction: transaction)
                self.handleChatState(message: xmppMessage, buddy: buddy)
                _message = OTRIncomingMessage(xmppMessage: xmppMessage, body: body, account: account, buddy: buddy, capabilities: self.capabilities)
            } else {
                let outgoing = OTROutgoingMessage(xmppMessage: xmppMessage, body: body, account: account, buddy: buddy, capabilities: self.capabilities)
                outgoing.dateSent = delayed ?? Date()
                _message = outgoing
            }
            guard let message = _message else {
                DDLogWarn("Discarding empty message: \(xmppMessage)")
                return
            }
            
            // Bail out if we receive duplicate messages identified by XEP-0359
            if self.isDuplicate(message: message, transaction: transaction) {
                DDLogWarn("Duplicate forwarded message received: \(xmppMessage)")
                return
            }
            
            if let delayed = delayed {
                message.date = delayed
            }
            preSave?(message, transaction)
            message.save(with: transaction)
            if let incoming = message as? OTRIncomingMessage {
                self.finishHandlingIncomingMessage(incoming, account: account, transaction: transaction)
            }
        }
    }
    
    /// Inserts direct message into database
    public func handleDirectMessage(_ message: XMPPMessage,
                                    body: String?,
                                    accountId: String,
                                    preSave: PreSave? = nil) {
        //var incomingMessage: OTRIncomingMessage? = nil
        connection.asyncReadWrite({ (transaction) in
            guard let account = OTRXMPPAccount.fetchObject(withUniqueID: accountId, transaction: transaction),
                let fromJID = message.from,
                let buddy = OTRXMPPBuddy.fetchBuddy(jid: fromJID, accountUniqueId: accountId, transaction: transaction)
                else {
                    return
            }

            // Update ChatState
            self.handleChatState(message: message, buddy: buddy)
            
            // Handle Delivery Receipts
            self.handleDeliveryResponse(message: message, transaction: transaction)
            
            // Update lastSeenDate
            // If we receive a message from an online buddy that counts as them interacting with us
            let status = OTRBuddyCache.shared.threadStatus(for: buddy)
            if status != .offline,
                !message.hasReceiptResponse,
                !message.isErrorMessage {
                OTRBuddyCache.shared.setLastSeenDate(Date(), for: buddy)
            }
            
            // Handle errors
            guard !message.isErrorMessage else {
                if let elementId = message.elementID,
                    let existingMessage = OTROutgoingMessage.message(forMessageId: elementId, transaction: transaction) {
                    if let outgoing = existingMessage as? OTROutgoingMessage {
                        outgoing.error = OTRXMPPError.error(for: message)
                        outgoing.save(with: transaction)
                    } else if existingMessage is OTRIncomingMessage,
                        let errorText = message.element(forName: "error")?.element(forName: "text")?.stringValue,
                        errorText.contains("OTR Error")
                    {
                        // automatically renegotiate a new session when there's an error
                        OTRProtocolManager.shared.encryptionManager.otrKit.initiateEncryption(withUsername: fromJID.bare, accountName: account.username, protocol: account.protocolTypeString())
                        
                    }
                }
                return
            }
            
            let incoming = OTRIncomingMessage(xmppMessage: message, body: body, account: account, buddy: buddy, capabilities: self.capabilities)
            
            // Check for duplicates
            if self.isDuplicate(message: incoming, transaction: transaction) {
                DDLogWarn("Duplicate message received: \(message)")
                return
            }
            guard let text = incoming.text, text.count > 0 else {
                // discard empty message text
                return
            }
            
            if text.isOtrText {
                OTRProtocolManager.shared.encryptionManager.otrKit.decodeMessage(text, username: buddy.username, accountName: account.username, protocol: kOTRProtocolTypeXMPP, tag: incoming)
            } else {
                preSave?(incoming, transaction)
                incoming.save(with: transaction)
                self.finishHandlingIncomingMessage(incoming, account: account, transaction: transaction)
            }
        })
    }
    
    private func finishHandlingIncomingMessage(_ message: OTRIncomingMessage, account: OTRXMPPAccount, transaction: YapDatabaseReadWriteTransaction) {
        guard let xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager else {
            return
        }
        xmpp.sendDeliveryReceipt(for: message)
        
        self.fileTransfer.createAndDownloadItemsIfNeeded(message: message, force: false, transaction: transaction)
        UIApplication.shared.showLocalNotification(message, transaction: transaction)
    }
}

// MARK: - Extensions

extension MessageStorage: XMPPCapabilitiesDelegate {
    public func xmppCapabilities(_ sender: XMPPCapabilities, didDiscoverCapabilities caps: XMLElement, for jid: XMPPJID) {
        
    }
}

extension MessageStorage: XMPPStreamDelegate {
    public func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        connection.asyncRead { (transaction) in
            guard let account = self.account(with: transaction) else { return }
            self.archiving.fetchHistory(archiveJID: nil, userJID: nil, since: account.lastHistoryFetchDate)
        }
    }
    
    public func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        // We don't handle incoming group chat messages here
        // Check out OTRXMPPRoomYapStorage instead
        guard message.messageType != .groupchat,
            message.element(forName: "x", xmlns: XMPPMUCUserNamespace) == nil,
            message.element(forName: "x", xmlns: XMPPConferenceXmlns) == nil,
            // We handle carbons elsewhere via XMPPMessageCarbonsDelegate
            !message.isMessageCarbon,
            // We handle MAM elsewhere as well
            message.mamResult == nil,
            // OMEMO messages cannot be processed here
            !message.omemo_hasEncryptedElement(.conversationsLegacy),
            let accountId = sender.accountId else {
            return
        }
        
        handleDirectMessage(message, body: nil, accountId: accountId)
    }
}

extension MessageStorage: XMPPMessageCarbonsDelegate {

    public func xmppMessageCarbons(_ xmppMessageCarbons: XMPPMessageCarbons, didReceive message: XMPPMessage, outgoing isOutgoing: Bool) {
        guard let accountId = xmppMessageCarbons.xmppStream?.accountId,
        !message.omemo_hasEncryptedElement(.conversationsLegacy) else {
            return
        }
        var _forJID: XMPPJID? = nil
        if !isOutgoing {
            _forJID = message.from
        } else {
            _forJID = message.to
        }
        guard let forJID = _forJID else { return }
        handleForwardedMessage(message, forJID: forJID, body: nil, accountId: accountId, delayed: nil, isIncoming: !isOutgoing)
    }
}

extension MessageStorage: XMPPMessageArchiveManagementDelegate {
    public func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFinishReceivingMessagesWith resultSet: XMPPResultSet) {
        connection.asyncReadWrite { (transaction) in
            guard let accountId = xmppMessageArchiveManagement.xmppStream?.accountId,
                let account = OTRXMPPAccount.fetchObject(withUniqueID: accountId, transaction: transaction)?.copyAsSelf() else {
                    return
            }
            account.lastHistoryFetchDate = Date()
            account.save(with: transaction)
        }
    }
    
    public func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFailToReceiveMessages error: XMPPIQ) {
        DDLogError("Failed to receive messages \(error)")
    }
    
    public func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didReceiveMAMMessage message: XMPPMessage) {
        guard let accountId = xmppMessageArchiveManagement.xmppStream?.accountId,
            let myJID = xmppMessageArchiveManagement.xmppStream?.myJID,
            let result = message.mamResult,
            let forwarded = result.forwardedMessage,
            let from = forwarded.from,
            !forwarded.omemo_hasEncryptedElement(.conversationsLegacy) else {
                DDLogVerbose("Discarding incoming MAM message \(message)")
                return
        }
        let delayed = result.forwardedStanzaDelayedDeliveryDate
        let isIncoming = !from.isEqual(to: myJID, options: .bare)
        var _forJID: XMPPJID? = nil
        if isIncoming {
            _forJID = forwarded.from
        } else {
            _forJID = forwarded.to
        }
        guard let forJID = _forJID else { return }
        handleForwardedMessage(forwarded, forJID: forJID, body: nil, accountId: accountId, delayed: delayed, isIncoming: isIncoming)
    }
}

// MARK: - Private Extensions


extension OTRChatState {
    static func chatState(from fromState: XMPPMessage.ChatState?) -> OTRChatState {
        guard let from = fromState else {
            return .unknown
        }
        var chatState: OTRChatState = .unknown
        switch from {
        case .composing:
            chatState = .composing
        case .paused:
            chatState = .paused
        case .active:
            chatState = .active
        case .inactive:
            chatState = .inactive
        case .gone:
            chatState = .gone
        }
        return chatState
    }
}

extension String {
    /// https://otr.cypherpunks.ca/Protocol-v3-4.0.0.html
    static let OTRWhitespaceStart = String(bytes: [0x20,0x09,0x20,0x20,0x09,0x09,0x09,0x09,0x20,0x09,0x20,0x09,0x20,0x09,0x20,0x20], encoding: .utf8)!
    
    /// for separately handling OTR messages
    var isOtrText: Bool {
        return self.contains("?OTR") || self.contains(String.OTRWhitespaceStart)
    }
}

extension OTRBaseMessage {
    /// You can override message body, for example if this is an encrypted message
    convenience init(xmppMessage: XMPPMessage, body: String?, account: OTRXMPPAccount, buddy: OTRXMPPBuddy, capabilities: XMPPCapabilities) {
        self.init()
        self.messageText = body ?? xmppMessage.body
        self.buddyUniqueId = buddy.uniqueId
        if let delayed = xmppMessage.delayedDeliveryDate {
            self.messageDate = delayed
        } else {
            self.messageDate = Date()
        }
        if let elementId = xmppMessage.elementID {
            self.messageId = elementId
        }
        
        // Extract XEP-0359 stanza-id
        self.originId = xmppMessage.originId
        self.stanzaId = xmppMessage.extractStanzaId(account: account, capabilities: capabilities)
        
        if let incoming = self as? OTRIncomingMessage {
            // Mark if read if it's on the screen
            // TODO: make this not dependent on global main thread variable
            if let yapKey = OTRAppDelegate.appDelegate.activeThreadYapKey,
                yapKey == incoming.threadId {
                incoming.read = true
            }
        }
    }
}

extension NSCopying {
    /// Creates a deep copy of the object
    func copyAsSelf() -> Self? {
        return self.copy() as? Self
    }
}

