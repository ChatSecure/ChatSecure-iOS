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
    // MARK: Properties
    private let connection: YapDatabaseConnection
    
    /// Capabilities must be activated elsewhere
    @objc public let capabilities: XMPPCapabilities
    @objc public let carbons: XMPPMessageCarbons
    @objc public let archiving: XMPPMessageArchiveManagement

    // MARK: Init
    deinit {
        self.carbons.removeDelegate(self)
        self.archiving.removeDelegate(self)
    }
    
    /// Capabilities must be activated elsewhere
    @objc public init(connection: YapDatabaseConnection,
                      capabilities: XMPPCapabilities,
                      dispatchQueue: DispatchQueue? = nil) {
        self.connection = connection
        self.capabilities = capabilities
        self.carbons = XMPPMessageCarbons(dispatchQueue: dispatchQueue)
        self.archiving = XMPPMessageArchiveManagement(dispatchQueue: dispatchQueue)
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
    
    /// Marks a previously sent outgoing message as delivered
    private func handleDeliveryResponse(message: XMPPMessage, transaction: YapDatabaseReadWriteTransaction) {
        guard message.hasReceiptResponse,
            !message.isErrorMessage,
            let responseId = message.receiptResponseID else {
                return
        }
        OTROutgoingMessage.receivedDeliveryReceipt(forMessageId: responseId, transaction: transaction)
    }
    
    /// It is a violation of the XMPP spec to discard messages with duplicate stanza elementIds. We must use XEP-0359 stanza-id only.
    private func isDuplicate(xmppMessage: XMPPMessage, stanzaId: String, buddyUniqueId: String, transaction: YapDatabaseReadTransaction) -> Bool {
        var result = false
        transaction.enumerateMessages(elementId: nil, originId: nil, stanzaId: stanzaId) { (message, stop) in
            if message.threadId == buddyUniqueId {
                result = true
                stop.pointee = true
            }
        }
        return result
    }
    
    /// Handles both MAM and Carbons
    private func handleForwardedMessage(_ xmppMessage: XMPPMessage,
                                        accountId: String,
                                        delayed: Date?,
                                        isIncoming: Bool) {
        guard xmppMessage.isMessageWithBody,
            !xmppMessage.isErrorMessage,
            let messageBody = xmppMessage.body,
            OTRKit.stringStarts(withOTRPrefix: messageBody) else {
            DDLogWarn("Discarding forwarded message: \(xmppMessage)")
            return
        }
        
        //Sent Message Carbons are sent by our account to another
        //So from is our JID and to is buddy
        var _jid: XMPPJID? = nil
        if isIncoming {
            _jid = xmppMessage.from
        } else {
            _jid = xmppMessage.to
        }
        guard let jid = _jid else {
            return
        }
        
        connection.asyncReadWrite { (transaction) in
            guard let account = OTRXMPPAccount.fetchObject(withUniqueID: accountId, transaction: transaction),
                let buddy = OTRXMPPBuddy.fetchBuddy(jid: jid, accountUniqueId: accountId, transaction: transaction) else {
                    return
            }
            var message: OTRBaseMessage? = nil
            if isIncoming {
                self.handleChatState(message: xmppMessage, buddy: buddy)
                self.handleDeliveryResponse(message: xmppMessage, transaction: transaction)
                message = OTRIncomingMessage(xmppMessage: xmppMessage, account: account, buddy: buddy, capabilities: self.capabilities)
            } else {
                message = OTROutgoingMessage(xmppMessage: xmppMessage, account: account, buddy: buddy, capabilities: self.capabilities)
            }
            guard let stanzaId = message?.stanzaId,
                !self.isDuplicate(xmppMessage: xmppMessage, stanzaId: stanzaId, buddyUniqueId: buddy.uniqueId, transaction: transaction) else {
                    DDLogWarn("Duplicate forwarded message received: \(xmppMessage)")
                    return
            }
            if let delayed = delayed {
                message?.date = delayed
            }
            message?.save(with: transaction)
        }
    }
    
    /// Inserts direct message into database
    private func handleDirectMessage(_ message: XMPPMessage, accountId: String) {
        connection.asyncReadWrite { (transaction) in
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
            
            let incoming = OTRIncomingMessage(xmppMessage: message, account: account, buddy: buddy, capabilities: self.capabilities)
            
            // Check for duplicates
            if let stanzaId = incoming.stanzaId,
                self.isDuplicate(xmppMessage: message, stanzaId: stanzaId, buddyUniqueId: buddy.uniqueId, transaction: transaction) {
                DDLogWarn("Duplicate message received: \(message)")
                return
            }
            
            // TODO: Replace this so we aren't passing everything through OTRKit
            if let text = incoming.text {
                OTRProtocolManager.shared.encryptionManager.otrKit.decodeMessage(text, username: buddy.username, accountName: account.username, protocol: kOTRProtocolTypeXMPP, tag: incoming)
            }
        }
    }
}

// MARK: - Extensions

extension MessageStorage: XMPPStreamDelegate {
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
            let accountId = sender.accountId else {
            return
        }
        
        handleDirectMessage(message, accountId: accountId)
    }
}

extension MessageStorage: XMPPMessageCarbonsDelegate {

    public func xmppMessageCarbons(_ xmppMessageCarbons: XMPPMessageCarbons, didReceive message: XMPPMessage, outgoing isOutgoing: Bool) {
        guard let accountId = xmppMessageCarbons.xmppStream?.accountId else {
            return
        }
        handleForwardedMessage(message, accountId: accountId, delayed: nil, isIncoming: !isOutgoing)
    }
}

extension MessageStorage: XMPPMessageArchiveManagementDelegate {
    public func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didReceiveMAMMessage message: XMPPMessage) {
        guard let accountId = xmppMessageArchiveManagement.xmppStream?.accountId,
            let myJID = xmppMessageArchiveManagement.xmppStream?.myJID,
            let result = message.mamResult,
            let forwarded = result.forwardedMessage,
            let delayed = result.forwardedStanzaDelayedDeliveryDate,
            let from = forwarded.from else {
                return
        }
        let isIncoming = !from.isEqual(to: myJID, options: .bare)
        handleForwardedMessage(forwarded, accountId: accountId, delayed: delayed, isIncoming: isIncoming)
    }
}

// MARK: - Private Extensions

extension XMPPStream {
    /// Stream tags should be the OTRXMPPAccount uniqueId
    var accountId: String? {
        return tag as? String
    }
}

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

extension OTRBaseMessage {
    convenience init(xmppMessage: XMPPMessage, account: OTRXMPPAccount, buddy: OTRXMPPBuddy, capabilities: XMPPCapabilities) {
        self.init()
        self.messageText = xmppMessage.body
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
