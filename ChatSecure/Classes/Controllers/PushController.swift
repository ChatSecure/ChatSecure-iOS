//
//  PushController.swift
//  ChatSecure
//
//  Created by David Chiles on 9/3/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS
import YapDatabase

extension Account {
    public class func yapCollection() -> String {
        return "ChatSecurePushColletion"
    }
}

/** 
    The purpose of this class is to tie together teh api client and teh data store, YapDatbase.
    It also provides some helper methods that makes dealing with the api easier
*/
public class PushController: NSObject {
    var apiClient : Client
    var databaseConnection: YapDatabaseConnection
    var callbackQueue = NSOperationQueue()
    
    public init(baseURL: NSURL, sessionConfiguration: NSURLSessionConfiguration, databaseConnection: YapDatabaseConnection) {
        self.apiClient = Client(baseUrl: baseURL, urlSessionConfiguration: sessionConfiguration, account: nil)
        self.databaseConnection = databaseConnection
    }
    
    func hasPushAccount() -> Bool {
        var hasAccount = false
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            transaction.enumerateKeysAndMetadataInCollection(Account.yapCollection(), usingBlock: { (key, metadata, stop) -> Void in
                hasAccount = true
                stop.initialize(true)
            })
        }
        return hasAccount
    }
    
    func createNewRandomPushAccount(completion:(success: Bool, error: NSError?) -> Void) {
        let username = NSUUID().UUIDString
        let password = OTRPasswordGenerator.passwordWithLength(OTRDefaultPasswordLength)
        
        self.apiClient.registerNewUser(username, password: password, email: nil) { (account, error) -> Void in
            if let newAccount = account {
                self.databaseConnection.readWriteWithBlock({ (t) -> Void in
                    t.setObject(newAccount, forKey: newAccount.username, inCollection:Account.yapCollection())
                })
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: true, error: nil)
                })
            } else {
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: error)
                })
            }
        }
    }
    
}