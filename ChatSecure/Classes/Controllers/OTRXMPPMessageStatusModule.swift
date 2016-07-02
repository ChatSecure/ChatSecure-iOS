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
    func didSendMessage(messageKey:String, messageCollection:String)
    func didFailToSendMessage(messageKey:String, messageCollection:String, error:NSError?)
}

/**
 This is a simple XMPP module that translates xmpp message events to OTRMessageEvents for the delegate. 
 Should be used in coordination with MessageQueueHandler.
 */
@objc public class OTRXMPPMessageStatusModule:XMPPModule,XMPPStreamDelegate {
    
    let databaseConnection:YapDatabaseConnection
    var delegate:OTRXMPPMessageStatusModuleDelegate?
    var delegateQueue = dispatch_queue_create("OTRXMPPMessageStatusModuleDelegate", DISPATCH_QUEUE_SERIAL)
    
    public init(databaseConnection:YapDatabaseConnection, delegate:OTRXMPPMessageStatusModuleDelegate?) {
        self.delegate = delegate
        self.databaseConnection = databaseConnection
        super.init(dispatchQueue: nil)
    }
    
    //Mark: YapDatbase functions
    
    private func fetchMessage(XMPPId:String) -> OTRMessageProtocol? {
        var message:OTRMessageProtocol? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            message = OTRMessage.messageForMessageId(XMPPId, incoming: false, transaction: transaction)
        }
        return message
    }
    
    //Mark: XMPPStream delegate functions
    public func xmppStream(sender: XMPPStream!, didSendMessage message: XMPPMessage!) {
        
        guard let messageId = message.attributeStringValueForName("id") where message.isChatMessage() else {
            return
        }
        
        if let message = self.fetchMessage(messageId) {
            self.delegate?.didSendMessage(message.messageKey(), messageCollection: message.messageCollection())
        }
    }
    
    public func xmppStream(sender: XMPPStream!, didFailToSendMessage message: XMPPMessage!, error: NSError!) {
        
        guard let messageId = message.attributeStringValueForName("id") where message.isChatMessage() else {
            return
        }
        
        if let message = self.fetchMessage(messageId) {
            self.delegate?.didFailToSendMessage(message.messageKey(), messageCollection: message.messageCollection(), error: error)
        }
        
    }
    
    
}
