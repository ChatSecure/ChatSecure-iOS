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
        return "ChatSecurePushAccountColletion"
    }
}

let yapThisDeviceKey = "OTRyapThisDeviceKey"

/** 
    The purpose of this class is to tie together the api client and the data store, YapDatabase.
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
    
    func registerThisDevice(apns:String, completion:(success: Bool, error: NSError?) -> Void) {
        self.apiClient.registerDevice(apns, name: nil, deviceID: nil) { (device, error) -> Void in
            if let newDevice = device {
                self.saveThisDevice(newDevice)
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
    
    func updateThisDevice(apns:String, completion:(success: Bool, error: NSError?) -> Void) {
        self.thisDevice { (device, error) -> Void in
            guard let id = device?.id else {
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    let error = NSError(domain: kOTRErrorDomain, code: 301, userInfo: [NSLocalizedDescriptionKey:"No device found. Need to create device first."])
                    completion(success: false, error:error)
                })
                return
            }
            
            self.apiClient.updateDevice(id, APNSToken: apns, name: device?.name, deviceID: device?.id, completion: { (device, error) -> Void in
                if let newDevice = device {
                    self.saveThisDevice(newDevice)
                    self.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: true, error:nil)
                    })
                } else {
                    self.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: false, error:error)
                    })
                }
            })
        }
    }
    
    func saveThisDevice(device:Device) {
        let deviceContainer = DeviceContainer()
        deviceContainer.pushDevice = device
        deviceContainer.pushAccountKey = self.apiClient.account?.username
        self.databaseConnection.readWriteWithBlock({ (transaction) -> Void in
            
        })
    }
    
    func thisDevice(completion:(device: Device?, error: NSError?) -> Void) {
        var device:Device? = nil
        self.databaseConnection.asyncReadWithBlock({ (transaction) -> Void in
            if let deviceContainer = transaction.objectForKey(yapThisDeviceKey, inCollection: DeviceContainer.collection()) as? DeviceContainer {
                device = deviceContainer.pushDevice
            }
            }) { () -> Void in
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(device: device,error: nil)
                })
        }
    }
    
    func createNewPushToken(deviceID deviceID:String, buddyKey:String, name:String?, completion:(tokenKey:String?,error:NSError?) -> Void) {
        self.apiClient.createToken(deviceID, name: name) { (token, error) -> Void in
            if let newToken = token {
                self.databaseConnection.readWriteWithBlock({ (transaction) -> Void in
                    let tokenContainer = TokenContainer()
                    tokenContainer.pushToken = newToken
                    tokenContainer.buddyKey = buddyKey
                    transaction.setObject(tokenContainer, forKey: tokenContainer.uniqueId, inCollection:TokenContainer.collection())
                })
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(tokenKey:newToken.tokenString,error:nil)
                })
            } else {
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(tokenKey:nil,error:error)
                })
            }
        }
    }
    
    func saveReceivedPushToken(tokenString:String, buddyKey:String, endpoint:String, completion:(success:Bool, error:NSError?)->Void) {
        
        self.databaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            guard let endpointURL = NSURL(string: endpoint) else  {
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: NSError(domain: kOTRErrorDomain, code: 302, userInfo: [NSLocalizedDescriptionKey:"Invalid URL"]))
                })
                return
            }
            
            let token = Token(tokenString: tokenString, deviceID: nil)
            
            let tokenContainer = TokenContainer()
            tokenContainer.pushToken = token
            tokenContainer.ownedByYou = false
            tokenContainer.endpoint = endpointURL
            tokenContainer.buddyKey = buddyKey
            
            tokenContainer.saveWithTransaction(transaction)
            
            self.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(success: true, error: nil)
            })
        }
        
    }
    
    func tokensForBuddy(buddyKey:String, transaction:YapDatabaseReadTransaction) throws -> [TokenContainer] {
        guard let buddy = transaction.objectForKey(buddyKey, inCollection: OTRBuddy.collection()) as? OTRBuddy else {
            throw NSError(domain: kOTRErrorDomain, code: 303, userInfo: [NSLocalizedDescriptionKey:"No buddy found"])
        }
        
        var tokens: [TokenContainer] = []
        if let relationshipTransaction = transaction.ext(OTRYapDatabaseRelationshipName) as? YapDatabaseRelationshipTransaction {
            relationshipTransaction.enumerateEdgesWithName(buddyTokenRelationshipEdgeName, destinationKey: buddy.uniqueId, collection: OTRBuddy.collection(), usingBlock: { (edge, stop) -> Void in
                
                if let tokenContainer = transaction.objectForKey(edge.sourceKey, inCollection: edge.sourceCollection) as? TokenContainer {
                    tokens.append(tokenContainer)
                }
                
            })
        }
        tokens.sortInPlace({ (first, second) -> Bool in
            switch first.date.compare(second.date) {
            case .OrderedAscending:
                return true
            default:
                return false
            }
        })
        
        return tokens
    }

    //MARK: Sending Message
    func sendKnock(buddyKey:String, completion:(success:Bool, error:NSError?) -> Void) {
        self.databaseConnection.asyncReadWithBlock { (t) -> Void in
            
            do {
                guard let token = try self.tokensForBuddy(buddyKey, transaction: t).first?.pushToken else {
                    self.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: false, error: NSError(domain: kOTRErrorDomain, code: 304, userInfo: [NSLocalizedDescriptionKey:"No tokens found"]))
                    })
                    return
                }
                let message = Message(token: token.tokenString, data: nil)
                
                self.apiClient.sendMessage(message, completion: { (message, error) -> Void in
                    if let _ = message {
                        self.callbackQueue.addOperationWithBlock({ () -> Void in
                            completion(success: true, error: nil)
                        })
                    } else {
                        self.callbackQueue.addOperationWithBlock({ () -> Void in
                            completion(success: false, error: error)
                        })
                    }
                })
            } catch let error as NSError {
                
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: error)
                })
            }
    
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}