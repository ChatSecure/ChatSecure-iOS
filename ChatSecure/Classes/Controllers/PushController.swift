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

/** 
    The purpose of this class is to tie together the api client and the data store, YapDatabase.
    It also provides some helper methods that makes dealing with the api easier
*/
public class PushController: NSObject, OTRPushTLVHandlerDelegate {
    var apiClient : Client
    var databaseConnection: YapDatabaseConnection
    var callbackQueue = NSOperationQueue()
    
    enum PushYapKeys: String {
        case thisDeviceKey = "kYapThisDeviceKey"
        case thisAccountKey = "kYapThisAccountKey"
    }
    
    enum PushYapCollections: String {
        case unusedTokenCollection = "kYapUnusedTokenCollection"
    }
    
    static let unusedTokenStoreSize:UInt = 50
    
    public init(baseURL: NSURL, sessionConfiguration: NSURLSessionConfiguration, databaseConnection: YapDatabaseConnection) {
        self.apiClient = Client(baseUrl: baseURL, urlSessionConfiguration: sessionConfiguration, account: nil)
        self.databaseConnection = databaseConnection
        super.init()
        self.apiClient.account = self.thisDevicePushAccount()
    }
    
    public func thisDevicePushAccount() -> Account? {
        var account:Account? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            account = transaction.objectForKey(PushYapKeys.thisAccountKey.rawValue, inCollection: Account.yapCollection()) as? Account
        }
        return account
    }
    
    public func hasPushAccount() -> Bool {
        var hasAccount = false
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            hasAccount = transaction.hasObjectForKey(PushYapKeys.thisAccountKey.rawValue, inCollection: Account.yapCollection())
        }
        return hasAccount
    }
    
    public func createNewRandomPushAccount(completion:(success: Bool, error: NSError?) -> Void) {
        
        //Username is limited to 30 characters and passwords are limited to 100
        var username = NSUUID().UUIDString
        username = username.substringToIndex(username.startIndex.advancedBy(30))
        var password = OTRPasswordGenerator.passwordWithLength(100)
        password = password.substringToIndex(password.startIndex.advancedBy(100))
        
        self.apiClient.registerNewUser(username, password: password, email: nil) {[weak self] (account, error) -> Void in
            if let newAccount = account {
                self?.apiClient.account = newAccount
                self?.databaseConnection.readWriteWithBlock({ (t) -> Void in
                    t.setObject(newAccount, forKey:PushYapKeys.thisAccountKey.rawValue, inCollection:Account.yapCollection())
                })
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: true, error: nil)
                })
            } else {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: error)
                })
            }
        }
    }
    
    public func registerThisDevice(apns:String, completion:(success: Bool, error: NSError?) -> Void) {
        self.apiClient.registerDevice(apns, name: nil, deviceID: nil) {[weak self] (device, error) -> Void in
            if let newDevice = device {
                self?.saveThisDevice(newDevice)
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: true, error: nil)
                })
                
            } else {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: error)
                })
            }
        }
    }
    
    public func updateThisDevice(apns:String, completion:(success: Bool, error: NSError?) -> Void) {
        self.thisDevice {[weak self] (device, error) -> Void in
            guard let id = device?.id else {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error:PushError.noPushDevice.error())
                })
                return
            }
            
            self?.apiClient.updateDevice(id, APNSToken: apns, name: device?.name, deviceID: device?.id, completion: {[weak self] (device, error) -> Void in
                if let newDevice = device {
                    self?.saveThisDevice(newDevice)
                    self?.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: true, error:nil)
                    })
                } else {
                    self?.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: false, error:error)
                    })
                }
            })
        }
    }
    
    func saveThisDevice(device:Device) {
        let deviceContainer = DeviceContainer()
        deviceContainer.pushDevice = device
        deviceContainer.pushAccountKey = PushYapKeys.thisAccountKey.rawValue
        self.databaseConnection.readWriteWithBlock({ (transaction) -> Void in
            transaction.setObject(deviceContainer, forKey:PushYapKeys.thisDeviceKey.rawValue, inCollection:DeviceContainer.collection())
        })
    }
    
    func thisDevice() -> Device? {
        var device:Device? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            if let deviceContainer = transaction.objectForKey(PushYapKeys.thisDeviceKey.rawValue, inCollection:DeviceContainer.collection()) as? DeviceContainer {
                device = deviceContainer.pushDevice
            }
        }
        return device
    }
    
    public func thisDevice(completion:(device: Device?, error: NSError?) -> Void) {
        var device:Device? = nil
        self.databaseConnection.asyncReadWithBlock({ (transaction) -> Void in
            device = self.thisDevice()
            }) {[weak self] () -> Void in
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(device: device,error: nil)
                })
        }
    }
    
    func unusedToken(transaction:YapDatabaseReadTransaction) -> TokenContainer? {
        var tokenContainer:TokenContainer? = nil
        transaction.enumerateKeysAndObjectsInCollection(PushYapCollections.unusedTokenCollection.rawValue, usingBlock: { (key, object, stop) -> Void in
            if let tc = object as? TokenContainer {
                tokenContainer = tc
            }
            stop.initialize(true)
        })
        return tokenContainer
    }
    
    public func getNewPushToken(buddyKey:String, completion:(tokenKey:String?,error:NSError?) -> Void) {
        var tokenContainer:TokenContainer? = nil
        self.databaseConnection.asyncReadWriteWithBlock({[weak self] (transaction) -> Void in
            //1. Get random token from database
            tokenContainer = self?.unusedToken(transaction)
            //2. Remove from unused colleciton
            if let key = tokenContainer?.uniqueId {
                transaction.removeObjectForKey(key, inCollection: PushYapCollections.unusedTokenCollection.rawValue)
            }
        }, completionBlock: {[weak self] () -> Void in
                //If no tokens found then update store and try again
                guard let newTokenContainer = tokenContainer else {
                    self?.updateUnusedTokenStore({[weak self] (success, error) -> Void in
                        if success {
                            self?.getNewPushToken(buddyKey, completion: completion)
                        } else {
                            self?.callbackQueue.addOperationWithBlock({ () -> Void in
                                completion(tokenKey: nil, error: error)
                            })
                        }
                    })
                    return
                }
                //3. Connect buddy to token and save to database
                newTokenContainer.buddyKey = buddyKey
                self?.databaseConnection.readWriteWithBlock({ (transaction) -> Void in
                    newTokenContainer.saveWithTransaction(transaction)
                })
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(tokenKey: newTokenContainer.pushToken?.tokenString, error: nil)
                })
            })
    }
    
    public
    
    
    func fetchNewPushToken(deviceID:String, name: String?, completion:(success:Bool,error:NSError?)->Void) {
        self.apiClient.createToken(deviceID, name: name) {[weak self] (token, error) -> Void in
            if let newToken = token {
                self?.databaseConnection.readWriteWithBlock({ (transaction) -> Void in
                    let tokenContainer = TokenContainer()
                    tokenContainer.pushToken = newToken
                    tokenContainer.accountKey = PushYapKeys.thisAccountKey.rawValue
                    transaction.setObject(tokenContainer, forKey:tokenContainer.uniqueId, inCollection:PushYapCollections.unusedTokenCollection.rawValue)
                })
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success:true,error:nil)
                })
            } else {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success:false,error:error)
                })
            }
        }

    }
    
    /**
    * This function checks to see if there are enough unused tokens left in the database based on 'unusedTokenStoreSize'.
    * If there are not enough tokens it fetches more and stores them in the 'unusedTokenCollection'
    * If any one POST request fails it will return error and succes == false but may have actually fetched some tokens
    
    @param completion this closure is called once a tokens have been fetched or on failure
    */
    public func updateUnusedTokenStore(completion:(success:Bool,error:NSError?) -> Void) {
        
        guard let id = self.thisDevice()?.id else {
            self.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(success: false, error: PushError.noPushDevice.error())
            })
            return;
        }
        
        var tokensToCreate:UInt = 0
        self.databaseConnection.asyncReadWithBlock({ (transaction) -> Void in
            let unusedTokens = transaction.numberOfKeysInCollection(PushYapCollections.unusedTokenCollection.rawValue)
            if unusedTokens < PushController.unusedTokenStoreSize {
                tokensToCreate = PushController.unusedTokenStoreSize
            }
            }) { [weak self] () -> Void in
                
                var error:NSError? = nil
                if tokensToCreate > 0 {
                    
                    let group = dispatch_group_create()
                    for _ in 0...tokensToCreate {
                        dispatch_group_enter(group)
                        self?.fetchNewPushToken(id, name: nil, completion: { (success, err) -> Void in
                            if err != nil {
                                error = err
                            }
                            dispatch_group_leave(group)
                        })
                    }
                    
                    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
                }
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    var succes = false
                    if error == nil {
                        succes = true
                    }
                    completion(success: succes, error: error)
                })
        }
    }
    
    public func saveReceivedPushToken(tokenString:String, buddyKey:String, endpoint:String, completion:(success:Bool, error:NSError?)->Void) {
        
        self.databaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            guard let endpointURL = NSURL(string: endpoint) else  {
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: PushError.invalidURL.error())
                })
                return
            }
            
            let token = Token(tokenString: tokenString, deviceID: nil)
            
            let tokenContainer = TokenContainer()
            tokenContainer.pushToken = token
            tokenContainer.endpoint = endpointURL
            tokenContainer.buddyKey = buddyKey
            
            tokenContainer.saveWithTransaction(transaction)
            
            self.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(success: true, error: nil)
            })
        }
        
    }
    
    public func tokensForBuddy(buddyKey:String, createdByThisAccount:Bool, transaction:YapDatabaseReadTransaction) throws -> [TokenContainer] {
        guard let buddy = transaction.objectForKey(buddyKey, inCollection: OTRBuddy.collection()) as? OTRBuddy else {
            throw PushError.noBuddyFound.error()
        }
        
        var tokens: [TokenContainer] = []
        if let relationshipTransaction = transaction.ext(OTRYapDatabaseRelationshipName) as? YapDatabaseRelationshipTransaction {
            relationshipTransaction.enumerateEdgesWithName(kBuddyTokenRelationshipEdgeName, destinationKey: buddy.uniqueId, collection: OTRBuddy.collection(), usingBlock: { (edge, stop) -> Void in
                
                if let tokenContainer = transaction.objectForKey(edge.sourceKey, inCollection: edge.sourceCollection) as? TokenContainer {
                    if tokenContainer.accountKey != nil && createdByThisAccount {
                        tokens.append(tokenContainer)
                    } else if tokenContainer.accountKey == nil && !createdByThisAccount {
                        tokens.append(tokenContainer)
                    }
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
    public func sendKnock(buddyKey:String, completion:(success:Bool, error:NSError?) -> Void) {
        self.databaseConnection.asyncReadWithBlock { (t) -> Void in
            
            do {
                guard let token = try self.tokensForBuddy(buddyKey, createdByThisAccount: false, transaction: t).first?.pushToken else {
                    self.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: false, error: PushError.noTokensFound.error())
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
    
    
    //MARK: APNS Token
    public func didRegisterForRemoteNotificationsWithDeviceToken(data:NSData) -> Void {
        let pushTokenString = data.hexString;
        if (!self.hasPushAccount()) {
            self.createNewRandomPushAccount({[weak self] (success, error) -> Void in
                if success {
                    self?.registerThisDevice(pushTokenString, completion: {[weak self] (success, error) -> Void in
                        if !success {
                            NSLog("Unable to register this device")
                        } else {
                            self?.updateUnusedTokenStore({ (success, error) -> Void in
                                if !success {
                                    NSLog("Unable to update store")
                                }
                            })
                        }
                    })
                }
            })
        } else {
            self.thisDevice({ [weak self] (device, error) -> Void in
                if device != nil {
                    self?.updateThisDevice(pushTokenString, completion: { (success, error) -> Void in
                        if !success {
                            NSLog("Unable to update this device")
                        } else {
                            self?.updateUnusedTokenStore({ (success, error) -> Void in
                                if !success {
                                    NSLog("Unable to update store")
                                }
                            })
                        }
                    })
                } else {
                    self?.registerThisDevice(pushTokenString, completion: { (success, error) -> Void in
                        if !success {
                            NSLog("Unable to register this device")
                        } else {
                            self?.updateUnusedTokenStore({ (success, error) -> Void in
                                if !success {
                                    NSLog("Unable to update store")
                                }
                            })
                        }
                    })
                }
            })
        }
    }
    
    //MARK: OTRPushTLVHandlerDelegate
    public func receivePushData(tlvData: NSData!, username: String!, accountName: String!, protocolString: String!) {
        
        var buddy:OTRBuddy? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            buddy = OTRBuddy.fetchBuddyForUsername(username, accountName: accountName, transaction: transaction)
        }
        
        guard let buddyKey = buddy?.uniqueId else {
            //Error fetching buddy
            return
        }
        
        do {
            let tokenArray = try PushDeserializer.deserializeToken(tlvData)
            for token in tokenArray {
                guard let tokenString = token.pushToken?.tokenString else {
                    return
                }
                
                guard let url = token.endpoint?.absoluteString else {
                    return
                }
                
                self.saveReceivedPushToken(tokenString, buddyKey: buddyKey, endpoint: url, completion: { (success, error) -> Void in
                    if !success {
                        NSLog("Error saving token")
                    }
                })
            }
        } catch {
            NSLog("Error handling TLV data")
        }
    }
    
    
    
    
}