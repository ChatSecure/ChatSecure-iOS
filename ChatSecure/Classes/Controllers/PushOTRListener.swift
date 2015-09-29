//
//  PushOTRListener.swift
//  ChatSecure
//
//  Created by David Chiles on 9/29/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation

class PushOTRListener {
    
    let queue = NSOperationQueue()
    var notification:NSObjectProtocol?
    weak var storage:PushStorageProtocol?
    
    init (storage:PushStorageProtocol?) {
        self.startObserving()
        self.storage = storage
    }
    
    func startObserving() {
        self.notification = NSNotificationCenter.defaultCenter().addObserverForName(OTRMessageStateDidChangeNotification, object: nil, queue: self.queue) {[weak self] (notification) -> Void in
            self?.handleNotification(notification)
        }
    }
    
    func handleNotification(notification:NSNotification) {
        guard let buddy = notification.object as? OTRBuddy else {
            return
        }
        
        if let dictionary = notification.userInfo as? [String:AnyObject] {
            let number = dictionary[OTRMessageStateKey] as? NSNumber
            if let enumValue = number?.unsignedLongValue where enumValue == OTREncryptionMessageState.Encrypted.rawValue {
                //We know the conversation just went encrypted
                //Check to see if we've given this buddy a token before
                //If we haven't then we need to transmit a token to them
                do {
                    if try self.storage?.tokensForBuddy(buddy.uniqueId, createdByThisAccount: true).count <= 0 {
                        //Couldn't find any tokens that we gave to this buddy
                        
                    }
                } catch {
                    NSLog("Error finding tokens")
                }
                
            }
            
        }
        
        
    }
    
    deinit {
        if let token = self.notification {
            NSNotificationCenter.defaultCenter().removeObserver(token)
        }
    }

}
