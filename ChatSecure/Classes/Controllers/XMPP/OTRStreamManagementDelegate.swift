//
//  OTRStreamManagementDelegate.swift
//  ChatSecure
//
//  Created by David Chiles on 6/15/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework
import YapDatabase

/**
 * The purpose of this class is to know if XEP-0198 is enabled and to mark messages when they are acknowledged by the server with the correct date
 */
@objc public class OTRStreamManagementDelegate:NSObject, XMPPStreamManagementDelegate {
    
    private(set) public var streamManagementEnabled = false
    private let databaseConnection:YapDatabaseConnection
    
    public init(databaseConnection:YapDatabaseConnection) {
        self.databaseConnection = databaseConnection
    }
    
    @objc public func xmppStreamManagement(sender: XMPPStreamManagement!, wasEnabled enabled: DDXMLElement!) {
        self.streamManagementEnabled = true
    }
    @objc public func xmppStreamManagement(sender: XMPPStreamManagement!, wasNotEnabled failed: DDXMLElement!) {
        self.streamManagementEnabled = false
    }
    
    @objc public func xmppStreamManagement(sender: XMPPStreamManagement!, didReceiveAckForStanzaIds stanzaIds: [AnyObject]!) {
        
        self.databaseConnection.asyncReadWriteWithBlock { (transaction) in
            for object in stanzaIds {
                guard let stanzaId = object as? String else {
                    return
                }
                
                if let message = OTRMessage.messageForMessageId(stanzaId, incoming: false, transaction: transaction) as? OTRMessage{
                    message.dateAcked = NSDate()
                    message.saveWithTransaction(transaction)
                }
            }
        }
        
        
    }
}