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
    let sendEncrypted:Bool
    let timer:NSTimer?
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
    
    public var accountTimeout:NSTimeInterval = 30
    public var otrTimeout:NSTimeInterval = 10
    public var messageTimeout:NSTimeInterval = 10
    
    let operationQueue = NSOperationQueue()
    let databaseConnection:YapDatabaseConnection
    weak var protocolManager = OTRProtocolManager.sharedInstance()
    private var outstandingMessages = [String:OutstandingMessageInfo]()
    private var outstandingBuddies = [String:OutstandingMessageInfo]()
    private var outstandingAccounts = [String:Set<OutstandingMessageInfo>]()
    private let isolationQueue = dispatch_queue_create("MessageQueueHandler-IsolationQueue", DISPATCH_QUEUE_SERIAL)
    var accountLoginNotificationObserver:NSObjectProtocol?
    var messageStateDidChangeNotificationObserver:NSObjectProtocol?
    
    public init(dbConnection:YapDatabaseConnection) {
        databaseConnection = dbConnection
        self.operationQueue.maxConcurrentOperationCount = 1
        super.init()
        self.accountLoginNotificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(kOTRProtocolLoginSuccess, object: nil, queue: self.operationQueue, usingBlock: { [weak self] (notification) in
            self?.handleAccountLoginNotification(notification)
        })
        self.messageStateDidChangeNotificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(OTRMessageStateDidChangeNotification, object: nil, queue: self.operationQueue) {[weak self] (notification) in
            self?.handleMessageStateDidChangeNotification(notification)
        }
    }
    
    deinit {
        if let observer = self.accountLoginNotificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
        
        if let observer = self.messageStateDidChangeNotificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
        
    }
    
    //MARK: Access to outstanding messages and account
    
    private func waitingForAccount(accountString:String,messageKey:String,messageCollection:String,sendEncrypted:Bool,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
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
            set.insert(OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection,sendEncrypted:sendEncrypted,timer:nil, completion: completion))
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
    
    private func waitingForBuddy(buddyKey:String,messageKey:String, messageCollection:String, sendEncrypted:Bool, timer:NSTimer,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
        let messageInfo = OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection,sendEncrypted:sendEncrypted, timer:nil, completion: completion)
        
        dispatch_async(self.isolationQueue) { 
            self.outstandingBuddies.updateValue(messageInfo, forKey: buddyKey)
        }
    }
    
    private func popWaitingBuddy(buddyKey:String) -> OutstandingMessageInfo? {
        var messageInfo:OutstandingMessageInfo? = nil
        dispatch_sync(self.isolationQueue) { 
            messageInfo = self.outstandingBuddies.removeValueForKey(buddyKey)
        }
        return messageInfo
    }
    
    private func waitingForMessage(messageKey:String,messageCollection:String,sendEncrypted:Bool,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        let messageInfo = OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection, sendEncrypted:sendEncrypted, timer:nil, completion: completion)
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
        
        guard let message = transaction.objectForKey(key, inCollection: collection) as? OTRMessage else {
            return nil
        }
        return message
    }
    
    //MARK: XMPPManager functions
    
    private func sendMessage(outstandingMessage:OutstandingMessageInfo) {
        self.operationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            var msg:OTRMessage? = nil
            strongSelf.databaseConnection.readWithBlock({ (transaction) in
                msg = transaction.objectForKey(outstandingMessage.messageKey, inCollection: outstandingMessage.messageCollection) as? OTRMessage
            })
            
            guard let message = msg else {
                outstandingMessage.completion(success: false, retryTimeout: -1)
                return
            }
            
            strongSelf.sendMessage(message, sendEncrypted: outstandingMessage.sendEncrypted, completion: outstandingMessage.completion)
        }
    }
    
    private func sendMessage(message:OTRMessage, sendEncrypted:Bool, completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
        var bud:OTRBuddy? = nil
        var acc:OTRAccount? = nil
        self.databaseConnection.readWithBlock({ (transaction) in
            bud = OTRBuddy.fetchObjectWithUniqueID(message.buddyUniqueId, transaction: transaction)
            if let accountKey = bud?.accountUniqueId {
                acc = OTRAccount.fetchObjectWithUniqueID(accountKey, transaction: transaction)
            }
            
        })
        guard let buddy = bud,account = acc else {
            completion(success: false, retryTimeout: -1)
            return
        }
        
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
            //Get necessary objects for OTRKit
            
            //We're connected now we need to check encryption requirements
            OTRKit.sharedInstance().messageStateForUsername(buddy.username, accountName: account.username, protocol: account.protocolTypeString(), completion: { (messageState) in
                // If we need to send it encrypted and we have a session or we don't need to encrypt send out message
                if ((sendEncrypted && messageState == .Encrypted) || !sendEncrypted) {
                    guard let text = message.text else {
                        return
                    }
                    self.waitingForMessage(message.uniqueId, messageCollection: messageCollection,sendEncrypted:sendEncrypted, completion: completion)
                    OTRKit.sharedInstance().encodeMessage(text, tlvs: nil, username:buddy.username , accountName: account.username, protocol: account.protocolTypeString(), tag: message)
                } else {
                    //We need to initate a session
                    let timer = NSTimer.scheduledTimerWithTimeInterval(self.otrTimeout, target: self, selector: #selector(MessageQueueHandler.otrInitatiateTimeout(_:)), userInfo: buddy.uniqueId, repeats: false)
                    self.waitingForBuddy(buddy.uniqueId, messageKey: message.uniqueId, messageCollection: messageCollection,sendEncrypted:sendEncrypted, timer:timer, completion: completion)
                    OTRKit.sharedInstance().initiateEncryptionWithUsername(buddy.username, accountName: account.username, protocol: account.protocolTypeString())
                    
                    //Timeout at some point waiting for OTR session
                    
                }
                
            })
            
            
        } else if (account.autologin == true) {
            self.waitingForAccount(account.uniqueId, messageKey: message.uniqueId, messageCollection: messageCollection,sendEncrypted:sendEncrypted, completion: completion)
            accountProtocol.connectWithPassword(account.password, userInitiated: false)
        } else {
            // The account might be connected then? even if not auto connecting we might just start up faster then the
            // can enter credentials. Try again in a bit myabe the account will be ready
            completion(success: false, retryTimeout: self.accountTimeout)
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
        var msg:OTRMessage? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            msg = self.fetchMessage(messageKey, collection: messageCollection, transaction: transaction)
        }
        
        guard let message = msg else {
            completion(success: false, retryTimeout: -1)
            return
        }
        
        self.sendMessage(message,sendEncrypted: messageSendingAction.sendEncrypted, completion: completion)
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
        
        guard let messageSet = self.popWaitingAccount(accountKey) else {
            return
        }
        
        for messageInfo in messageSet {
            self.sendMessage(messageInfo)
        }
    }
    
    //Mark: Callback for OTRSession
    
    private func handleMessageStateDidChangeNotification(notification:NSNotification) {
        guard let buddy = notification.object as? OTRBuddy,
            messageStateInt = (notification.userInfo?[OTRMessageStateKey] as? NSNumber)?.unsignedLongValue else {
            return
        }
        
        if let messageState = OTRKitMessageState(rawValue: messageStateInt) where messageState == .Encrypted {
            // Buddy has gone encrypted
            // Check if we have an outstanding messages for this buddy
            guard let messageInfo = self.popWaitingBuddy(buddy.uniqueId) else {
                return
            }
            //Cancle outsanding timer
            messageInfo.timer?.invalidate()
            self.sendMessage(messageInfo)
        }
    }
    
    //Mark: OTR timeout
    @objc public func otrInitatiateTimeout(timer:NSTimer) {
        
        guard let buddyKey = timer.userInfo as? String, messageInfo = self.popWaitingBuddy(buddyKey) else {
            return
        }
        messageInfo.completion(success: false, retryTimeout: self.messageTimeout)
    }
    
    //MARK: Callback from protocol
    public func didSendMessage(messageKey: String, messageCollection: String) {
        
        guard let messageInfo = self.popWaitingMessage(messageKey, messageCollection: messageCollection) else {
            return;
        }
        
        //Update date sent
        self.databaseConnection.asyncReadWriteWithBlock { (transaction) in
            guard let message = transaction.objectForKey(messageKey, inCollection: messageCollection)?.copy() as? OTRMessage else {
                return
            }
            message.dateSent = NSDate()
            message.saveWithTransaction(transaction)
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