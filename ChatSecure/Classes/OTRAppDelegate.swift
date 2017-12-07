//
//  OTRAppDelegate.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 12/5/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

public extension OTRAppDelegate {
    /// Returns key/collection of visible thread, or nil if not visible or unset
    @objc public static func visibleThread(_ block: @escaping (_ thread: YapCollectionKey?)->(), completionQueue: DispatchQueue? = nil) {
        DispatchQueue.main.async {
            let messagesVC = OTRAppDelegate.appDelegate.messagesViewController
            guard messagesVC.isViewLoaded,
                messagesVC.view.window != nil,
                let key = messagesVC.threadKey,
                let collection = messagesVC.threadCollection else {
                block(nil)
                return
            }
            let ck = YapCollectionKey(collection: collection, key: key)
            if let completionQueue = completionQueue {
                completionQueue.async {
                    block(ck)
                }
            } else {
                block(ck)
            }
        }
    }
    
    /// Temporary hack to fix corrupted development database. Empty incoming MAM messages were stored as unread
    @objc public func fixUnreadMessageCount(_ completion: ((_ unread: UInt) -> Void)?) {
        OTRDatabaseManager.shared.readWriteDatabaseConnection?.asyncReadWrite({ (transaction) in
            var messagesToRemove: [OTRIncomingMessage] = []
            var messagesToMarkAsRead: [OTRIncomingMessage] = []
            transaction.enumerateUnreadMessages({ (message, stop) in
                guard let incoming = message as? OTRIncomingMessage else {
                    return
                }
                if let buddy = incoming.buddy(with: transaction),
                    let _ = buddy.account(with: transaction),
                    incoming.messageText == nil {
                    messagesToMarkAsRead.append(incoming)
                } else {
                    messagesToRemove.append(incoming)
                }
            })
            messagesToRemove.forEach({ (message) in
                DDLogInfo("Deleting orphaned message: \(message)")
                message.remove(with: transaction)
            })
            messagesToMarkAsRead.forEach({ (message) in
                DDLogInfo("Marking message with no text as read \(message)")
                if let message = message.copyAsSelf() {
                    message.read = true
                    message.save(with: transaction)
                }
            })
        }, completionBlock: {
            var unread: UInt = 0
            OTRDatabaseManager.shared.readWriteDatabaseConnection?.asyncRead({ (transaction) in
                unread = transaction.numberOfUnreadMessages()
            }, completionBlock: {
                completion?(unread)
            })
        })
    }
}
