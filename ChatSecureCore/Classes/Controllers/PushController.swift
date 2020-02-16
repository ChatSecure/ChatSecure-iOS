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
import UserNotifications
import OTRKit

@objc public protocol PushControllerProtocol {
    
    func sendKnock(_ buddyKey:String, completion:@escaping (_ success:Bool, _ error:NSError?) -> Void)
    func receiveRemoteNotification(_ notification:[AnyHashable: Any], completion: @escaping (_ buddy:OTRBuddy?, _ error:NSError?) -> Void)
    func pushStorage() -> PushStorageProtocol?
}

@objc public enum PushPreference: Int {
    case undefined
    case disabled
    case enabled
}

@objc(OTRPushInfo)
public class PushInfo: NSObject {
    let pushOptIn = PushController.getPushPreference() == .enabled
    let pushAPIURL: URL
    let hasPushAccount: Bool
    let numUsedTokens: UInt
    let numUnusedTokens: UInt
    let pushPermitted: Bool
    let backgroundFetchPermitted = UIApplication.shared.backgroundRefreshStatus == .available
    let lowPowerMode: Bool
    let pubsubEndpoint: String?
    let device: Device?
    
    /// all of these need to be true for push to work, but it doesn't guarantee it actually works
    public func pushMaybeWorks() -> Bool {
        return  pushOptIn &&
                hasPushAccount &&
                pushPermitted &&
                backgroundFetchPermitted &&
                !lowPowerMode &&
                numUsedTokens > 0 &&
                device != nil
    }
    
    init(pushAPIURL: URL, hasPushAccount: Bool, numUsedTokens: UInt, numUnusedTokens: UInt, pushPermitted: Bool, pubsubEndpoint: String?, device: Device?) {
        self.pushAPIURL = pushAPIURL
        self.hasPushAccount = hasPushAccount
        self.numUsedTokens = numUsedTokens
        self.numUnusedTokens = numUnusedTokens
        self.pushPermitted = pushPermitted
        var lowPower = false
        if #available(iOS 9.0, *) {
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        self.lowPowerMode = lowPower
        self.pubsubEndpoint = pubsubEndpoint
        self.device = device
    }
}

/**
    The purpose of this class is to tie together the api client and the data store, YapDatabase.
    It also provides some helper methods that makes dealing with the api easier
*/
open class PushController: NSObject, PushControllerProtocol {
    
    private var _storage: PushStorageProtocol?
    private var storage: PushStorageProtocol? {
        if _storage == nil,
            let write = connections?.write {
            let storage = PushStorage(databaseConnection: write)
            finishStorageSetup(storage: storage)
            _storage = storage
        }
        return _storage
    }
    var apiClient : Client
    var callbackQueue = OperationQueue()
    let timeBufffer:TimeInterval = 60*60*24
    var pubsubEndpoint: NSString?
    private var connections: DatabaseConnections? {
        return OTRDatabaseManager.shared.connections
    }
    
    @objc public init(baseURL: URL, sessionConfiguration: URLSessionConfiguration, databaseConnection: YapDatabaseConnection? = nil) {
        self.apiClient = Client(baseUrl: baseURL, urlSessionConfiguration: sessionConfiguration, account: nil)
        super.init()
    }
    
    private func finishStorageSetup(storage: PushStorageProtocol) {
        var account: Account? = nil;
        connections?.read.asyncRead({ (transaction) in
            account = storage.thisDevicePushAccount()
        }, completionBlock: {
            self.apiClient.account = account
            storage.removeAllOurExpiredUnusedTokens(self.timeBufffer, completion: nil)
        })
    }
    
    /// This will delete all your push data and disable push
    public func deactivate(completion: (()->())?, callbackQueue: DispatchQueue?) {
        apiClient.unregister { (success, error) in
            PushController.setPushPreference(.disabled)
            self.storage?.deleteEverything(completion: completion, callbackQueue: callbackQueue)
            self.apiClient.account = nil
        }
    }
    
    /// This calls deactivate and then re-enables push
    public func reset(completion: (()->())?, callbackQueue: DispatchQueue?) {
        self.deactivate(completion: { [weak self] in
            PushController.setPushPreference(.enabled)
            self?.createNewRandomPushAccount { (success, error) in
                if success {
                    PushController.registerForPushNotifications()
                }
                if let completion = completion {
                    let queue = callbackQueue ?? DispatchQueue.main
                    queue.async(execute: {
                        completion()
                    })
                }
            }
            }, callbackQueue: callbackQueue)
    }
    
    @objc open func createNewRandomPushAccount(_ completion:@escaping (_ success: Bool, _ error: NSError?) -> Void) {
        
        //Username is limited to 30 characters and passwords are limited to 100
        var username = UUID().uuidString
        username = String(username.prefix(30))
        guard var password = OTRPasswordGenerator.password(withLength: 100) else {
            self.callbackQueue.addOperation({ () -> Void in
                completion(false, nil)
            })
            return;
        }
        password = String(password.prefix(100))
        
        self.apiClient.registerNewUser(username, password: password, email: nil) {[weak self] (account, error) -> Void in
            if let newAccount = account {
                self?.apiClient.account = newAccount
                self?.storage?.saveThisAccount(newAccount)
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(true, nil)
                })
            } else {
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false, error)
                })
            }
        }
    }
    
    /**
     A simple function to access the underlying push storage object
     
     - returns: The push storage object that controls storing and retrieving push tokens
     */
    @objc open func pushStorage() -> PushStorageProtocol? {
        return self.storage
    }
    
    @objc open func registerThisDevice(_ apns:String, completion:@escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.apiClient.registerDevice(apns, name: nil, deviceID: nil) {[weak self] (device, error) -> Void in
            if let newDevice = device {
                self?.storage?.saveThisDevice(newDevice)
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(true, nil)
                })
                
            } else {
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false, error)
                })
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: OTRPushAccountDeviceChanged), object: self, userInfo:nil)
        }
    }
    
    @objc open func updateThisDevice(_ apns:String, completion:@escaping (_ success: Bool, _ error: Error?) -> Void) {
        DispatchQueue.global().async {[weak self] () -> Void in
            guard let device = self?.storage?.thisDevice() else {
                self?.callbackQueue.addOperation({ () -> Void in
                    
                    completion(false, NSError.chatSecureError(PushError.noPushDevice, userInfo: nil))
                })
                return
            }
            
            guard let id = device.id else {
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false, NSError.chatSecureError(PushError.noPushDevice, userInfo: nil))
                })
                return
            }
            
            self?.apiClient.updateDevice(id, APNSToken: apns, name: device.name, deviceID: device.id, completion: {[weak self] (device, error) -> Void in
                if let newDevice = device {
                    self?.storage?.saveThisDevice(newDevice)
                    self?.callbackQueue.addOperation({ () -> Void in
                        completion(true, nil)
                    })
                } else {
                    self?.callbackQueue.addOperation({ () -> Void in
                        completion(false, error)
                    })
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: OTRPushAccountDeviceChanged), object: self, userInfo:nil)
            })
        }
        
    }
    
    @objc open func getPubsubEndpoint(_ completion:@escaping (_ endpoint:String?,_ error:Error?) -> Void) {
        if let pubsubEndpoint = pubsubEndpoint {
            self.callbackQueue.addOperation({ 
                completion(pubsubEndpoint as String, nil)
            })
            return
        }
        self.apiClient.getPubsubEndpoint { (pubsubEndpoint, error) in
            self.pubsubEndpoint = pubsubEndpoint as NSString?
            self.callbackQueue.addOperation({
                completion(pubsubEndpoint, error)
            })
        }
    }
    
    @objc open func getMessagesEndpoint() -> URL {
        return self.apiClient.messageEndpont()
    }
    
    @objc open func getNewPushToken(_ buddyKey:String?, completion:@escaping (_ token:TokenContainer?,_ error:NSError?) -> Void) {
        DispatchQueue.global().async {[weak self] () -> Void in
            guard let tokenContainer = self?.storage?.unusedToken() else {
                self?.updateUnusedTokenStore({[weak self] (success, error) -> Void in
                    if success {
                        self?.getNewPushToken(buddyKey, completion: completion)
                    } else {
                        self?.callbackQueue.addOperation({ () -> Void in
                            completion(nil, error as NSError?)
                        })
                    }
                    })
                return
            }
            
            self?.storage?.removeUnusedToken(tokenContainer)
            if let buddyKey = buddyKey {
                self?.storage?.associateBuddy(tokenContainer, buddyKey: buddyKey)
            } else {
                self?.storage?.saveUsedToken(tokenContainer)
            }
            self?.callbackQueue.addOperation({ () -> Void in
                completion(tokenContainer, nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: OTRPushAccountTokensChanged), object: self, userInfo:nil)
            })
        }
    }
    
    fileprivate func fetchNewPushToken(_ deviceID:String, name: String?, completion:@escaping (_ success:Bool,_ error:Error?)->Void) {
        self.apiClient.createToken(deviceID, name: name) {[weak self] (token, error) -> Void in
            if let newToken = token {
                guard let tokenContainer = TokenContainer() else {
                    self?.callbackQueue.addOperation({ () -> Void in
                        completion(false,nil)
                    })
                    return
                }
                tokenContainer.pushToken = newToken
                self?.storage?.saveUnusedToken(tokenContainer)
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(true,nil)
                })
            } else {
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false,error)
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
    @objc open func updateUnusedTokenStore(_ completion:@escaping (_ success:Bool,_ error:Error?) -> Void) {
        
        DispatchQueue.global().async {[weak self] () -> Void in
            guard let id = self?.storage?.thisDevice()?.id else {
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false, NSError.chatSecureError(PushError.noPushDevice, userInfo: nil))
                })
                return;
            }
            
            var tokensToCreate:UInt = 0
            
            guard let unusedTokens = self?.storage?.numberUnusedTokens() else {
                return;
            }
            
            guard let minimumCount = self?.storage?.unusedTokenStoreMinimum() else {
                return;
            }
            
            if unusedTokens < minimumCount  {
                tokensToCreate = minimumCount
            }
            
            //If we have less than minimumCount unused tokens left we need to refetch another batch.
            var error:Error? = nil
            if tokensToCreate > 0 {
                
                let group = DispatchGroup()
                for _ in 1...tokensToCreate {
                    group.enter()
                    self?.fetchNewPushToken(id, name: nil, completion: { (success, err) -> Void in
                        if err != nil {
                            error = err
                        }
                        group.leave()
                    })
                }
                
                _ = group.wait(timeout: DispatchTime.distantFuture)
            }
            self?.callbackQueue.addOperation({ () -> Void in
                var succes = false
                if error == nil {
                    succes = true
                }
                completion(succes, error)
            })

        }
    }
    
    @objc open func saveReceivedPushToken(_ tokenString:String, buddyKey:String, endpoint:String, completion:@escaping (_ success:Bool, _ error:NSError?)->Void) {
        
        DispatchQueue.global().async {[weak self] () -> Void in
            guard let endpointURL = URL(string: endpoint) else  {
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false, NSError.chatSecureError(PushError.invalidURL, userInfo: nil))
                })
                return
            }
            
            let token = Token(tokenString: tokenString, type: .unknown, deviceID: nil)
            
            guard let tokenContainer = TokenContainer() else {
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false, nil)
                })
                return
            }
            tokenContainer.pushToken = token
            tokenContainer.endpoint = endpointURL
            tokenContainer.buddyKey = buddyKey
            self?.storage?.saveUsedToken(tokenContainer)
            self?.callbackQueue.addOperation({ () -> Void in
                completion(true, nil)
            })
        }
        
    }
    
    @objc open func tokensForBuddy(_ buddyKey:String, createdByThisAccount:Bool, transaction:YapDatabaseReadTransaction) throws -> [TokenContainer] {
        guard let buddy = transaction.object(forKey: buddyKey, inCollection: OTRBuddy.collection) as? OTRBuddy else {
            throw NSError.chatSecureError(PushError.noBuddyFound, userInfo: nil)
        }
        
        var tokens: [TokenContainer] = []
        if let relationshipTransaction = transaction.ext(DatabaseExtensionName.relationshipExtensionName.name()) as? YapDatabaseRelationshipTransaction {
            relationshipTransaction.enumerateEdges(withName: kBuddyTokenRelationshipEdgeName, destinationKey: buddy.uniqueId, collection: OTRBuddy.collection, using: { (edge, stop) -> Void in
                
                if let tokenContainer = transaction.object(forKey: edge.sourceKey, inCollection: edge.sourceCollection) as? TokenContainer {
                    if tokenContainer.accountKey != nil && createdByThisAccount {
                        tokens.append(tokenContainer)
                    } else if tokenContainer.accountKey == nil && !createdByThisAccount {
                        tokens.append(tokenContainer)
                    }
                }
                
            })
        }
        tokens.sort(by: { (first, second) -> Bool in
            switch first.date.compare(second.date as Date) {
            case .orderedAscending:
                return true
            default:
                return false
            }
        })
        
        return tokens
    }
    
    //MARK: Receiving remote notification
    public func receiveRemoteNotification(_ notification: [AnyHashable : Any], completion: @escaping (OTRBuddy?, NSError?) -> Void) {
        do {
            let message = try Deserializer.messageFromPushDictionary(notification)
            guard let buddy = self.storage?.buddy(message.token) else {
                self.callbackQueue.addOperation({ () -> Void in
                    completion(nil, NSError.chatSecureError(PushError.noBuddyFound, userInfo: nil))
                })
                return;
            }
            
            self.callbackQueue.addOperation({ () -> Void in
                completion(buddy, nil)
            })
            
            
            
            
        } catch let error as NSError{
            self.callbackQueue.addOperation({ () -> Void in
                completion(nil, error)
            })
        }
    }

    //MARK: Sending Message
    @objc open func sendKnock(_ buddyKey:String, completion:@escaping (_ success:Bool, _ error:NSError?) -> Void) {
        DispatchQueue.global().async {[weak self] () -> Void in
            do {
                guard let token = try self?.storage?.tokensForBuddy(buddyKey, createdByThisAccount: false).first else {
                    self?.callbackQueue.addOperation({ () -> Void in
                        completion(false, NSError.chatSecureError(PushError.noTokensFound, userInfo: nil))
                    })
                    return
                }
                
                guard let tokenString = token.pushToken?.tokenString else {
                    self?.callbackQueue.addOperation({ () -> Void in
                        completion(false, NSError.chatSecureError(PushError.noTokensFound, userInfo: nil))
                    })
                    return
                }
                
                guard let url = token.endpoint else {
                    self?.callbackQueue.addOperation({ () -> Void in
                        completion(false, NSError.chatSecureError(PushError.missingAPIEndpoint, userInfo: nil))
                    })
                    return
                }
                
                let message = Message(token: tokenString, url:url , data: nil)
                
                self?.apiClient.sendMessage(message, completion: {[weak self] (message, error) -> Void in
                    
                    if ((error as NSError?)?.code == 404) {
                        // Token was revoked or was never valid.
                        self?.storage?.removeToken(token)
                        // Retry and see if we have another token to use or will error out with noTokensFound
                        self?.sendKnock(buddyKey, completion: completion)
                    }
                    else if let _ = message {
                        self?.callbackQueue.addOperation({ () -> Void in
                            completion(true, nil)
                        })
                    } else {
                        self?.callbackQueue.addOperation({ () -> Void in
                            completion(false, error as NSError?)
                        })
                    }
                })
            } catch let error as NSError {
                
                self?.callbackQueue.addOperation({ () -> Void in
                    completion(false, error)
                })
            }
        }
    }
    
    
    //MARK: APNS Token
    @objc open func didRegisterForRemoteNotificationsWithDeviceToken(_ data:Data) -> Void {
        
        DispatchQueue.global().async {[weak self] () -> Void in
            let pushTokenString = data.hexString();
            guard let storage = self?.storage else {
                return
            }
            
            if (!storage.hasPushAccount()) {
                self?.createNewRandomPushAccount({[weak self] (success, error) -> Void in
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
            }
            else {
                if let _ = storage.thisDevice() {
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
            }
        }
    }
    
    //MARK: OTRPushTLVHandlerDelegate
    @objc open func receivePush(_ tlvData: Data!, username: String!, accountName: String!, protocolString: String!, fingerprint:OTRFingerprint!) {
        
        let buddy = self.storage?.buddy(username, accountName: accountName)
        
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
                
                // Don't store tokens for Tor accounts
                let account = self.storage?.account(buddy!.accountUniqueId)
                if account?.accountType == OTRAccountType.xmppTor {
                    return
                }
                
                self.saveReceivedPushToken(tokenString, buddyKey: buddyKey, endpoint: url, completion: { (success, error) -> Void in
                    if !success {
                        //NSLog("Error saving token")
                    }
                })
            }
        } catch {
            //NSLog("Error handling TLV data")
        }
    }
    
    //MARK: Push Preferences
    
    @objc public static func getPushPreference() -> PushPreference {
        guard let value = UserDefaults.standard.object(forKey: kOTRPushEnabledKey) as? NSNumber else {
            return .undefined
        }
        if value.boolValue == true {
            return .enabled
        } else {
            return .disabled
        }
    }
    
    public static func setPushPreference(_ preference: PushPreference) {
        var bool = false
        if preference == .enabled {
            bool = true
        }
        UserDefaults.standard.set(bool, forKey: kOTRPushEnabledKey)
        UserDefaults.standard.synchronize()
    }
    
    //MARK: Utility
    
    /// If callbackQueue is nil, it will complete on main queue
    public func gatherPushInfo(completion: @escaping (PushInfo?) -> (), callbackQueue: DispatchQueue = DispatchQueue.main) {
        guard let storage = self.storage else {
            callbackQueue.async {
                completion(nil)
            }
            return
        }
        var pubsubEndpoint: String?
        var pushPermitted = false
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            PushController.canReceivePushNotifications(completion: { (enabled) in
                pushPermitted = enabled
                group.leave()
            })
        }
        group.enter()
        getPubsubEndpoint { (endpoint, error) in
            pubsubEndpoint = endpoint
            group.leave()
        }
        group.notify(queue: .main) {
            let device = storage.thisDevice()
            let newPushInfo = PushInfo(
                pushAPIURL: self.apiClient.baseUrl,
                hasPushAccount: storage.hasPushAccount(),
                numUsedTokens: storage.numberUsedTokens(),
                numUnusedTokens: storage.numberUnusedTokens(),
                pushPermitted: pushPermitted,
                pubsubEndpoint: pubsubEndpoint,
                device: device)
            callbackQueue.async {
                completion(newPushInfo)
            }
        }
    }
    
    @objc public static func registerForPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { (granted, error) in
            DispatchQueue.main.async(execute: {
                // TODO: Handle push registration error
                let app = UIApplication.shared
                NotificationCenter.default.post(name: Notification.Name(rawValue: OTRUserNotificationsChanged), object: app.delegate, userInfo:nil)
            })
        })
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    @objc public static func canReceivePushNotifications(completion: @escaping (Bool)->Void) {
        UNUserNotificationCenter.current?.getNotificationSettings { (settings) in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    @objc public static func openAppSettings() {
        guard let appSettings = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(appSettings)
    }
}

extension UNUserNotificationCenter {
    /// XCTest & UNUserNotificationCenter: requires bundle identifier, crashes when accessed
    /// http://www.openradar.me/27768556
    static var current: UNUserNotificationCenter? {
        // Return if this is a unit test
        if let _ = NSClassFromString("XCTest") {
            return nil
        } else {
            return .current()
        }
    }
}
