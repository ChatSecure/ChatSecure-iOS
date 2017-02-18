//
//  PushOTRListener.swift
//  ChatSecure
//
//  Created by David Chiles on 9/29/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS

/**
* Listen for changes from EncryptionManager for changes in state and when detetced going encrypted
* ensures push token is transfered
*/
class PushOTRListener: NSObject {
    
    let queue = OperationQueue()
    var notification:NSObjectProtocol?
    weak var storage:PushStorageProtocol?
    weak var pushController:PushController?
    weak var tlvHandler:OTRPushTLVHandlerProtocol?
    
    init (storage:PushStorageProtocol?, pushController:PushController?, tlvHandler:OTRPushTLVHandlerProtocol?) {
        self.storage = storage
        self.pushController = pushController
        self.tlvHandler = tlvHandler
        super.init()
        self.startObserving()
    }
    
    func startObserving() {
        self.notification = NotificationCenter.default.addObserver(forName: NSNotification.Name.OTRMessageStateDidChange, object: nil, queue: self.queue) {[weak self] (notification) -> Void in
            self?.handleNotification(notification)
        }
    }
    
    func handleNotification(_ notification:Notification) {
        guard let buddy = notification.object as? OTRBuddy else {
            return
        }
        
        if let dictionary = notification.userInfo as? [String:AnyObject] {
            let number = dictionary[OTRMessageStateKey] as? NSNumber
            if let enumValue = number?.uintValue, enumValue == OTREncryptionMessageState.encrypted.rawValue {
                
                
                if let account = self.storage?.account(buddy.accountUniqueId) {
                    //Everytime we're starting a new OTR Session we resend a new fresh push token either from the server or the cache
                    self.pushController?.getNewPushToken(buddy.uniqueId, completion: {[weak self] (t, error) -> Void in
                        if let token = t, let pushToken = token.pushToken {
                            do {
                                try self?.sendOffToken(pushToken, buddyUsername: buddy.username, accountUsername: account.username, protocol: account.protocolTypeString())
                            } catch let error as NSError {
                                
                                if  (error.code == PushError.misingExpiresDate.rawValue) {
                                    self?.pushController?.storage.removeToken(token)
                                    //Somehow we got a token without a expires date. We need to clear the database of these tokens and try again
                                    guard let timeBuffer = self?.pushController?.timeBufffer else {
                                        return
                                    }
                                    
                                    self?.pushController?.storage.removeAllOurExpiredUnusedTokens(timeBuffer, completion: { (count) in
                                        //try again
                                        self?.handleNotification(notification)
                                    })
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func sendOffToken(_ token:Token, buddyUsername:String, accountUsername:String, protocol:String) throws -> Void {
        if let url = self.pushController?.apiClient.messageEndpont().absoluteString {
            if let data = try PushSerializer.serialize([token], APIEndpoint: url) {
                self.tlvHandler?.sendPush(data, username: buddyUsername, accountName:accountUsername  , protocol: `protocol`)
            }
        }
    }
    
    deinit {
        if let token = self.notification {
            NotificationCenter.default.removeObserver(token)
        }
    }

}
