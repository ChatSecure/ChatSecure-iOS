      //
//  MessageQueueHandler.swift
//  ChatSecure
//
//  Created by David Chiles on 5/4/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import YapTaskQueue
      
/// This is just small struct to store the necessary inormation about a message while we wait for delegate callbacks from the XMPPStream
private struct OutstandingMessageInfo {
    let messageKey:String
    let messageCollection:String
    let completion:((success: Bool, retryTimeout: NSTimeInterval) -> Void)
}

/// Needed so we can store the struct in a dictionary 
extension OutstandingMessageInfo: Hashable {
    var hashValue: Int {
        get {
            return "\(self.messageKey)\(self.messageCollection)".hashValue
        }
    }
}

extension OutstandingMessageInfo: Equatable {}
private func ==(lhs: OutstandingMessageInfo, rhs: OutstandingMessageInfo) -> Bool {
    return lhs.messageKey == rhs.messageKey && lhs.messageCollection == rhs.messageCollection
}

public class MessageQueueHandler:NSObject, YapTaskQueueHandler, OTRXMPPMessageStatusModuleDelegate {
    
    let operationQueue = NSOperationQueue()
    let databaseConnection:YapDatabaseConnection
    weak var protocolManager = OTRProtocolManager.sharedInstance()
    private var outstandingMessages = [String:OutstandingMessageInfo]()
    private var outstandingAccounts = [String:Set<OutstandingMessageInfo>]()
    private let isolationQueue = dispatch_queue_create("MessageQueueHandler-IsolationQueue", DISPATCH_QUEUE_SERIAL)
    var notificationObserver:NSObjectProtocol?
    
    public init(dbConnection:YapDatabaseConnection) {
        databaseConnection = dbConnection
        self.operationQueue.maxConcurrentOperationCount = 1
        super.init()
        self.notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(kOTRProtocolLoginSuccess, object: nil, queue: self.operationQueue, usingBlock: { [weak self] (notification) in
            self?.handleAccountLoginNotification(notification)
        })
    }
    
    deinit {
        if let observer = self.notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
        
    }
    
    //MARK: Access to outstanding messages and account
    
    private func waitingForAccount(accountString:String,messageKey:String,messageCollection:String,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
        dispatch_async(self.isolationQueue) {
            
            // Get the set out or create a new one
            var messageSet = self.outstandingAccounts[accountString]
            if messageSet == nil {
                messageSet = Set<OutstandingMessageInfo>()
            }
            
            // Guarantee set is real
            guard var set = messageSet else {
                return
            }
            // Add new item
            set.insert(OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection, completion: completion))
            //Insert back into dictionary
            self.outstandingAccounts.updateValue(set, forKey: accountString)
        }
        
        
    }
    
    private func popWaitingAccount(accountString:String) -> Set<OutstandingMessageInfo>? {
        var messageInfoSet:Set<OutstandingMessageInfo>? = nil
        dispatch_sync(self.isolationQueue) {
            messageInfoSet = self.outstandingAccounts.removeValueForKey(accountString)
        }
        
        return messageInfoSet
    }
    
    private func waitingForMessage(messageKey:String,messageCollection:String,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        let messageInfo = OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection, completion: completion)
        let key = "\(messageKey)\(messageCollection)"
        
        dispatch_async(self.isolationQueue) { 
            self.outstandingMessages.updateValue(messageInfo, forKey: key)
        }
    }
    
    private func popWaitingMessage(messageKey:String,messageCollection:String) -> OutstandingMessageInfo? {
        var messageInfo:OutstandingMessageInfo? = nil
        let key = "\(messageKey)\(messageCollection)"
        dispatch_sync(self.isolationQueue) { 
            messageInfo = self.outstandingMessages.removeValueForKey(key)
        }
        
        return messageInfo
    }
    
    //MARK: Database Functions
    
    private func fetchMessage(key:String, collection:String, transaction:YapDatabaseReadTransaction) -> OTRMessage? {
        
        guard let message = transaction .objectForKey(key, inCollection: collection) as? OTRMessage else {
            return nil
        }
        return message
    }
    
    private func fetchAccount(buddyKey:String, transaction:YapDatabaseReadTransaction) -> OTRAccount? {
        
        guard let buddy = OTRBuddy.fetchObjectWithUniqueID(buddyKey, transaction: transaction) else {
            return nil
        }
        
        guard let acct = OTRAccount.fetchObjectWithUniqueID(buddy.accountUniqueId, transaction: transaction) else {
            return nil
        }
        
        return acct
    }
    
    //MARK: XMPPManager functions
    
    private func sendMessage(message:OTRMessage, account:OTRAccount, completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
        //Get the XMPP procol manager associated with this message and therefore account
        guard let accountProtocol:OTRProtocol = self.protocolManager?.protocolForAccount(account) else {
            completion(success: false, retryTimeout: -1)
            return
        }
        
        /**
         * Message is considered successuflly sent if the stream responds with didSendMessage.
         * When XEP-0198 is enabled and when an ack is reveived in (x) seconds then it is later makered as failed. It is up to the user to resubmit
         * a msesage to be sent.
         */
        //Some way to store a message dictionary with the key and block
        let messageCollection = OTRMessage.collection()
        
        
        //Ensure protocol is connected or if not and autologin then connnect
        if (accountProtocol.connectionStatus() == .Connected) {
            self.waitingForMessage(message.uniqueId, messageCollection: messageCollection, completion: completion)
            accountProtocol.sendMessage(message)
        } else if (account.autologin == true) {
            self.waitingForAccount(account.uniqueId, messageKey: message.uniqueId, messageCollection: messageCollection, completion: completion)
            accountProtocol.connectWithPassword(account.password, userInitiated: false)
        } else {
            // Maybe try again in a bit. the account might be connected then? even if not auto connecting we might just start up faster then the
            // can enter credentials
        }

    }
    
    //MARK: YapTaskQueueHandler Protocol
    
    public func handleNextItem(action: YapTaskQueueAction, completion: (success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        //Get the real message out of the database
        guard let messageSendingAction = action as? OTRYapMessageSendAction else {
            return
        }
        
        let messageKey = messageSendingAction.messsageKey
        let messageCollection = messageSendingAction.messageCollection
        var acct:OTRAccount? = nil
        var msg:OTRMessage? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            guard let message = self.fetchMessage(messageKey, collection: messageCollection, transaction: transaction) else {
                return
            }
            acct = self.fetchAccount(message.buddyUniqueId, transaction: transaction)
            msg = message
        }
        
        guard let account = acct else {
            // This action item did not have an account. We're on the wrong queue and something has gone wrong
            completion(success: false, retryTimeout: -1)
            return
        }
        
        guard let message = msg else {
            completion(success: false, retryTimeout: -1)
            return
        }
        
        self.sendMessage(message, account: account, completion: completion)
    }
    
    //Mark: Callback for Account
    
    private func handleAccountLoginNotification(notification:NSNotification) {
        guard let userInfo = notification.userInfo as? [String:AnyObject] else {
            return
        }
        if let accountKey = userInfo[kOTRNotificationAccountUniqueIdKey] as? String, accountCollection = userInfo[kOTRNotificationAccountCollectionKey] as? String  {
            self.didConnectAccount(accountKey, accountCollection: accountCollection)
        }
    }
    
    private func didConnectAccount(accountKey:String, accountCollection:String) {
        /** Try to send the message here
         1. Make sure this account matches our message
         2. Send out message if it does
        */
        guard let messageSet = self.popWaitingAccount(accountKey) else {
            return
        }
        
        self.databaseConnection.asyncReadWithBlock { [weak self] (transaction) in
            let strongSelf = self
            guard let account = transaction.objectForKey(accountKey, inCollection: accountCollection) as? OTRAccount else {
                return
            }
            
            for messageInfo in messageSet {
                guard let message = transaction.objectForKey(messageInfo.messageKey, inCollection: messageInfo.messageCollection) as? OTRMessage else {
                    return
                }
                
                strongSelf?.operationQueue.addOperationWithBlock({ 
                    strongSelf?.sendMessage(message, account: account, completion: messageInfo.completion)
                })
            }
        }
    }
    
    //MARK: Callback from protocol
    public func didSendMessage(messageKey: String, messageCollection: String) {
        
        guard let messageInfo = self.popWaitingMessage(messageKey, messageCollection: messageCollection) else {
            return;
        }
        
        messageInfo.completion(success: true, retryTimeout: -1)
    }
    
    public func didFailToSendMessage(messageKey:String, messageCollection:String) {
        guard let messageInfo = self.popWaitingMessage(messageKey, messageCollection: messageCollection) else {
            return;
        }
        
        messageInfo.completion(success: false, retryTimeout: -1)
    }
    
}