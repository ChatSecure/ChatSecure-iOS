//
//  OTRXMPPMessageStatusModule.swift
//  ChatSecure
//
//  Created by David Chiles on 5/5/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

@objc public protocol OTRXMPPMessageStatusModuleDelegate {
    func didSendMessage(_ messageKey:String, messageCollection:String)
    func didFailToSendMessage(_ messageKey:String, messageCollection:String, error:NSError?)
}

/**
 This is a simple XMPP module that translates xmpp message events to OTRMessageEvents for the delegate. 
 Should be used in coordination with MessageQueueHandler.
 */
@objc open class OTRXMPPMessageStatusModule:XMPPModule,XMPPStreamDelegate {
    
    let databaseConnection:YapDatabaseConnection
    var delegate:OTRXMPPMessageStatusModuleDelegate?
    var delegateQueue = DispatchQueue(label: "OTRXMPPMessageStatusModuleDelegate", attributes: [])
    
    @objc public init(databaseConnection:YapDatabaseConnection, delegate:OTRXMPPMessageStatusModuleDelegate?) {
        self.delegate = delegate
        self.databaseConnection = databaseConnection
        super.init(dispatchQueue: nil)
    }
    
    //Mark: YapDatbase functions
    
    fileprivate func fetchMessage(_ XMPPId:String) -> OTRMessageProtocol? {
        var message:OTRMessageProtocol? = nil
        self.databaseConnection.read { (transaction) in
            message = OTRBaseMessage.message(forMessageId: XMPPId, incoming: false, transaction: transaction)
        }
        return message
    }
    
    //Mark: XMPPStream delegate functions
    open func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        guard message.isChatMessage || message.isGroupChatMessage,
            let messageId = message.attributeStringValue(forName: "id") else {
            return
        }
        if let message = self.fetchMessage(messageId) {
            self.delegate?.didSendMessage(message.messageKey, messageCollection: message.messageCollection)
        }
    }
    
    open func xmppStream(_ sender: XMPPStream, didFailToSend message: XMPPMessage, error: Error) {
        guard message.isChatMessage || message.isGroupChatMessage,
            let messageId = message.attributeStringValue(forName: "id") else {
            return
        }
        
        if let message = self.fetchMessage(messageId) {
            self.delegate?.didFailToSendMessage(message.messageKey, messageCollection: message.messageCollection, error: error as NSError?)
        }
        
    }
    
    
}
