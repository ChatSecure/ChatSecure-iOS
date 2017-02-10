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
    let messageSecurity:OTRMessageTransportSecurity
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
    
    public var accountRetryTimeout:NSTimeInterval = 30
    public var otrTimeout:NSTimeInterval = 7
    public var messageRetryTimeout:NSTimeInterval = 10
    public var maxFailureCount:UInt = 2
    
    let operationQueue = NSOperationQueue()
    let databaseConnection:YapDatabaseConnection
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
    
    private func waitingForAccount(accountString:String,messageKey:String,messageCollection:String,messageSecurity:OTRMessageTransportSecurity,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
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
            set.insert(OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection,messageSecurity:messageSecurity,timer:nil, completion: completion))
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
    
    private func waitingForBuddy(buddyKey:String,messageKey:String, messageCollection:String, messageSecurity:OTRMessageTransportSecurity, timer:NSTimer,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
        let messageInfo = OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection,messageSecurity:messageSecurity, timer:nil, completion: completion)
        
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
    
    private func waitingForMessage(messageKey:String,messageCollection:String,messageSecurity:OTRMessageTransportSecurity,completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        let messageInfo = OutstandingMessageInfo(messageKey: messageKey, messageCollection: messageCollection, messageSecurity:messageSecurity, timer:nil, completion: completion)
        let key = "\(messageKey)\(messageCollection)"
        
        dispatch_async(self.isolationQueue) { 
            self.outstandingMessages.updateValue(messageInfo, forKey: key)
        }
    }
    
    /** 
     * Remove a waiting message info from the outstaning message dictionary. After the message info is removed the completion block should be called.
     * This ensures that the outstandingMessages dictionary is accessed from the correct queue.
     * 
     * - parameter messageKey: The yap database messsage key.
     * - parameter messageCollection: The yap database message key.
     * - returns: The OutstandingMessageInfo if one exists. Removed from the waiting dictioanry.
     */
    private func popWaitingMessage(messageKey:String,messageCollection:String) -> OutstandingMessageInfo? {
        var messageInfo:OutstandingMessageInfo? = nil
        let key = "\(messageKey)\(messageCollection)"
        dispatch_sync(self.isolationQueue) { 
            messageInfo = self.outstandingMessages.removeValueForKey(key)
        }
        
        return messageInfo
    }
    
    //MARK: Database Functions
    
    private func fetchMessage(key:String, collection:String, transaction:YapDatabaseReadTransaction) -> OTROutgoingMessage? {
        
        guard let message = transaction.objectForKey(key, inCollection: collection) as? OTROutgoingMessage else {
            return nil
        }
        return message
    }
    
    private func fetchSendingAction(messageKey:String, messageCollection:String, transaction:YapDatabaseReadTransaction) -> OTRYapMessageSendAction? {
        let key = OTRYapMessageSendAction.actionKeyForMessageKey(messageKey, messageCollection: messageCollection)
        guard let action = OTRYapMessageSendAction.fetchObjectWithUniqueID(key, transaction: transaction) else {
            return nil
        }
        return action
    }
    
    //MARK: XMPPManager functions
    
    private func sendMessage(outstandingMessage:OutstandingMessageInfo) {
        self.operationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            var msg:OTROutgoingMessage? = nil
            strongSelf.databaseConnection.readWithBlock({ (transaction) in
                msg = transaction.objectForKey(outstandingMessage.messageKey, inCollection: outstandingMessage.messageCollection) as? OTROutgoingMessage
            })
            
            guard let message = msg else {
                outstandingMessage.completion(success: true, retryTimeout: 0.0)
                return
            }
            
            strongSelf.sendMessage(message, completion: outstandingMessage.completion)
        }
    }
    
    private func sendMessage(message:OTROutgoingMessage, completion:(success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        
        var bud:OTRBuddy? = nil
        var acc:OTRAccount? = nil
        self.databaseConnection.readWithBlock({ (transaction) in
            bud = OTRBuddy.fetchObjectWithUniqueID(message.buddyUniqueId, transaction: transaction)
            if let accountKey = bud?.accountUniqueId {
                acc = OTRAccount.fetchObjectWithUniqueID(accountKey, transaction: transaction)
            }
            
        })
        guard let buddy = bud,account = acc else {
            completion(success: true, retryTimeout: 0.0)
            return
        }
        
        //Get the XMPP procol manager associated with this message and therefore account
        guard let accountProtocol = OTRProtocolManager.sharedInstance().protocolForAccount(account) as? OTRXMPPManager else {
            completion(success: true, retryTimeout: 0.0)
            return
        }
        
        /**
         * Message is considered successuflly sent if the stream responds with didSendMessage.
         * When XEP-0198 is enabled and when an ack is reveived in (x) seconds then it is later makered as failed. It is up to the user to resubmit
         * a msesage to be sent.
         */
        //Some way to store a message dictionary with the key and block
        let messageCollection = OTROutgoingMessage.collection()
        
        
        //Ensure protocol is connected or if not and autologin then connnect
        if (accountProtocol.connectionStatus() == .Connected) {
            
            //Make sure we have some text to send
            guard let text = message.text else {
                return
            }
            
            //Get necessary objects for OTRKit
            if (message.messageSecurity() == .OMEMO) {
                guard let signalCoordinator = accountProtocol.omemoSignalCoordinator else {
                    self.databaseConnection.asyncReadWriteWithBlock({ (transaction) in
                        guard let message = OTROutgoingMessage.fetchObjectWithUniqueID(message.uniqueId, transaction: transaction)?.copy() as? OTROutgoingMessage else {
                            return
                        }
                        message.error = NSError.chatSecureError(EncryptionError.OMEMONotSuported, userInfo: nil)
                        message.saveWithTransaction(transaction)
                    })
                    completion(success: true, retryTimeout: 0.0)
                    return
                }
                self.waitingForMessage(message.uniqueId, messageCollection: messageCollection, messageSecurity:message.messageSecurity(), completion: completion)
                
                
                
                signalCoordinator.encryptAndSendMessage(text, buddyYapKey: message.buddyUniqueId, messageId: message.messageId, completion: { [weak self] (success, error) in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if (success == false) {
                        //Something went wrong getting ready to send the message
                        //Save error object to message
                        strongSelf.databaseConnection.readWriteWithBlock({ (transaction) in
                            guard let message = OTROutgoingMessage.fetchObjectWithUniqueID(message.uniqueId, transaction: transaction)?.copy() as? OTROutgoingMessage else {
                                return
                            }
                            message.error = error
                            message.saveWithTransaction(transaction)
                        })
                        
                        if let messageInfo = strongSelf.popWaitingMessage(message.uniqueId, messageCollection: message.dynamicType.collection()) {
                            //Even though we were not succesfull in sending a message. The action needs to be removed from the queue so the next message can be handled.
                            messageInfo.completion(success: true, retryTimeout: 0.0)
                        }
                    }
                })
            } else if (message.messageSecurity() == .OTR || buddy.preferredSecurity == .PlaintextWithOTR) {
                //We're connected now we need to check encryption requirements
                let otrKit = OTRProtocolManager.sharedInstance().encryptionManager.otrKit
                let messageState = otrKit.messageStateForUsername(buddy.username, accountName: account.username, protocol: account.protocolTypeString())
                    
                // If we need to send it encrypted and we have a session or we don't need to encrypt send out message
                if (messageState == .Encrypted || buddy.preferredSecurity == .PlaintextWithOTR) {
                    self.waitingForMessage(message.uniqueId, messageCollection: messageCollection, messageSecurity:message.messageSecurity(), completion: completion)
                    otrKit.encodeMessage(text, tlvs: nil, username:buddy.username , accountName: account.username, protocol: account.protocolTypeString(), tag: message)
                } else {
                    //We need to initiate an OTR session
                    
                    //Timeout at some point waiting for OTR session
                    dispatch_async(dispatch_get_main_queue(), { 
                        let timer = NSTimer.scheduledTimerWithTimeInterval(self.otrTimeout, target: self, selector: #selector(MessageQueueHandler.otrInitatiateTimeout(_:)), userInfo: buddy.uniqueId, repeats: false)
                        self.waitingForBuddy(buddy.uniqueId, messageKey: message.uniqueId, messageCollection: messageCollection,messageSecurity:message.messageSecurity(), timer:timer, completion: completion)
                        otrKit.initiateEncryptionWithUsername(buddy.username, accountName: account.username, protocol: account.protocolTypeString())
                    })
                }
            } else if (message.messageSecurity() == .Plaintext) {
                self.waitingForMessage(message.uniqueId, messageCollection: messageCollection, messageSecurity:message.messageSecurity(), completion: completion)
                OTRProtocolManager.sharedInstance().sendMessage(message)
            }
        } else if (account.autologin == true) {
            self.waitingForAccount(account.uniqueId, messageKey: message.uniqueId, messageCollection: messageCollection, messageSecurity:message.messageSecurity(), completion: completion)
            accountProtocol.connectUserInitiated(false)
        } else {
            // The account might be connected then? even if not auto connecting we might just start up faster then the
            // can enter credentials. Try again in a bit myabe the account will be ready
            
            // Decided that this won't go into the retry failure because we're just waiting on the user to manually connect the account.
            // Not really a 'failure' but we should still try to push the messages through at some point.
            
            completion(success: false, retryTimeout: self.accountRetryTimeout)
        }

    }
    
    //MARK: YapTaskQueueHandler Protocol
    
    public func handleNextItem(action: YapTaskQueueAction, completion: (success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        //Get the real message out of the database
        guard let messageSendingAction = action as? OTRYapMessageSendAction else {
            return
        }
        
        let messageKey = messageSendingAction.messageKey
        let messageCollection = messageSendingAction.messageCollection
        var msg:OTROutgoingMessage? = nil
        self.databaseConnection.readWithBlock { (transaction) in
            msg = self.fetchMessage(messageKey, collection: messageCollection, transaction: transaction)
        }
        
        guard let message = msg else {
            // Somehow we have an action without a message. This is very strange. Do not like.
            // We tell the queue broker that we handle it successfully so it will be rmeoved and go on to the next action.
            completion(success: true, retryTimeout: 0.0)
            return
        }
        
        self.sendMessage(message, completion: completion)
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
            let messageStateInt = (notification.userInfo?[OTRMessageStateKey] as? NSNumber)?.unsignedLongValue else {
            return
        }
        
        if  messageStateInt == OTREncryptionMessageState.Encrypted.rawValue {
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
        
        guard let buddyKey = timer.userInfo as? String else {
            return
        }
        
        self.operationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else {return}
            
            guard let messageInfo = strongSelf.popWaitingBuddy(buddyKey) else {
                return
            }
            
            let err = NSError.chatSecureError(EncryptionError.UnableToCreateOTRSession, userInfo: nil)
            
            strongSelf.databaseConnection.readWriteWithBlock({ (transaction) in
                if let message = transaction.objectForKey(messageInfo.messageKey, inCollection: messageInfo.messageCollection)?.copy() as? OTRBaseMessage {
                    message.error = err
                    message.saveWithTransaction(transaction)
                }
            })
            
            
            messageInfo.completion(success: true, retryTimeout: 0.0)
        }
        
    }
    
    //MARK: Callback from protocol
    public func didSendMessage(messageKey: String, messageCollection: String) {
        
        guard let messageInfo = self.popWaitingMessage(messageKey, messageCollection: messageCollection) else {
            return;
        }
        
        //Update date sent
        self.databaseConnection.asyncReadWriteWithBlock { (transaction) in
            guard let message = transaction.objectForKey(messageKey, inCollection: messageCollection)?.copy() as? OTROutgoingMessage else {
                return
            }
            message.dateSent = NSDate()
            message.saveWithTransaction(transaction)
        }
        
        messageInfo.completion(success: true, retryTimeout: 0.0)
    }
    
    public func didFailToSendMessage(messageKey:String, messageCollection:String, error:NSError?) {
        guard let messageInfo = self.popWaitingMessage(messageKey, messageCollection: messageCollection) else {
            return;
        }
        
        //Even though this action failed we need to keep the queue moving.
        messageInfo.completion(success: true, retryTimeout: 0.0)
    }
    
}
