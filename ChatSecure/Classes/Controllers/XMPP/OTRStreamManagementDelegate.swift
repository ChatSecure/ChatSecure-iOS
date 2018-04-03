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
@objc open class OTRStreamManagementDelegate:NSObject, XMPPStreamManagementDelegate {
    
    @objc fileprivate(set) open var streamManagementEnabled = false
    fileprivate let databaseConnection:YapDatabaseConnection
    
    @objc public init(databaseConnection:YapDatabaseConnection) {
        self.databaseConnection = databaseConnection
    }
    
    @objc open func xmppStreamManagement(_ sender: XMPPStreamManagement, wasEnabled enabled: XMLElement) {
        self.streamManagementEnabled = true
    }
    @objc open func xmppStreamManagement(_ sender: XMPPStreamManagement, wasNotEnabled failed: XMLElement) {
        self.streamManagementEnabled = false
    }
    
    @objc open func xmppStreamManagement(_ sender: XMPPStreamManagement, didReceiveAckForStanzaIds stanzaIds: [Any]) {
        
        self.databaseConnection.asyncReadWrite { (transaction) in
            for object in stanzaIds {
                guard let stanzaId = object as? String else {
                    return
                }
                
                if let message = OTROutgoingMessage.message(forMessageId: stanzaId, transaction: transaction) as? OTROutgoingMessage{
                    message.dateAcked = Date()
                    message.save(with: transaction)
                }
            }
        }
        
        
    }
}
