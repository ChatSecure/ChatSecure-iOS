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

@objc public protocol PushControllerProtocol {
    
    func sendKnock(buddyKey:String, completion:(success:Bool, error:NSError?) -> Void)
    func receiveRemoteNotification(notification:[NSObject:AnyObject], completion:(buddy:OTRBuddy?, error:NSError?) -> Void)
    func pushStorage() -> PushStorageProtocol
}

@objc public enum PushPreference: Int {
    case Undefined
    case Disabled
    case Enabled
}

@objc(OTRPushInfo)
public class PushInfo: NSObject {
    let pushOptIn = PushController.getPushPreference() == .Enabled
    let pushAPIURL: NSURL
    let hasPushAccount: Bool
    let numUsedTokens: UInt
    let numUnusedTokens: UInt
    let pushPermitted: Bool
    let backgroundFetchPermitted = UIApplication.sharedApplication().backgroundRefreshStatus == .Available
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
    
    init(pushAPIURL: NSURL, hasPushAccount: Bool, numUsedTokens: UInt, numUnusedTokens: UInt, pushPermitted: Bool, pubsubEndpoint: String?, device: Device?) {
        self.pushAPIURL = pushAPIURL
        self.hasPushAccount = hasPushAccount
        self.numUsedTokens = numUsedTokens
        self.numUnusedTokens = numUnusedTokens
        self.pushPermitted = pushPermitted
        var lowPower = false
        if #available(iOS 9.0, *) {
            lowPower = NSProcessInfo.processInfo().lowPowerModeEnabled
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
public class PushController: NSObject, OTRPushTLVHandlerDelegate, PushControllerProtocol {
    
    let storage: PushStorageProtocol
    var apiClient : Client
    var callbackQueue = NSOperationQueue()
    var otrListener: PushOTRListener?
    let timeBufffer:NSTimeInterval = 60*60*24
    var pubsubEndpoint: NSString?
    
    public init(baseURL: NSURL, sessionConfiguration: NSURLSessionConfiguration, databaseConnection: YapDatabaseConnection, tlvHandler:OTRPushTLVHandlerProtocol?) {
        self.apiClient = Client(baseUrl: baseURL, urlSessionConfiguration: sessionConfiguration, account: nil)
        self.storage = PushStorage(databaseConnection: databaseConnection)
        super.init()
        self.apiClient.account = self.storage.thisDevicePushAccount()
        self.otrListener = PushOTRListener(storage: self.storage, pushController: self, tlvHandler: tlvHandler)
        self.storage.removeAllOurExpiredUnusedTokens(self.timeBufffer, completion: nil)
    }
    
    /// This will delete all your push data and disable push
    public func deactivate(completion: dispatch_block_t?, callbackQueue: dispatch_queue_t?) {
        PushController.setPushPreference(.Disabled)
        self.storage.deleteEverything(completion, callbackQueue: callbackQueue)
    }
    
    /// This calls deactivate and then re-enables push
    public func reset(completion: dispatch_block_t?, callbackQueue: dispatch_queue_t?) {
        deactivate({ [weak self] in
            PushController.setPushPreference(.Enabled)
            self?.createNewRandomPushAccount { (success, error) in
                if success {
                    PushController.registerForPushNotifications()
                }
                if let completion = completion {
                    dispatch_async(callbackQueue ?? dispatch_get_main_queue(), {
                        completion()
                    })
                }
            }
            }, callbackQueue: callbackQueue)
    }
    
    public func createNewRandomPushAccount(completion:(success: Bool, error: NSError?) -> Void) {
        
        //Username is limited to 30 characters and passwords are limited to 100
        var username = NSUUID().UUIDString
        username = username.substringToIndex(username.startIndex.advancedBy(30))
        guard var password = OTRPasswordGenerator.passwordWithLength(100) else {
            self.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(success: false, error: nil)
            })
            return;
        }
        password = password.substringToIndex(password.startIndex.advancedBy(100))
        
        self.apiClient.registerNewUser(username, password: password, email: nil) {[weak self] (account, error) -> Void in
            if let newAccount = account {
                self?.apiClient.account = newAccount
                self?.storage.saveThisAccount(newAccount)
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
    
    /**
     A simple function to access the underlying push storage object
     
     - returns: The push storage object that controls storing and retrieving push tokens
     */
    public func pushStorage() -> PushStorageProtocol {
        return self.storage
    }
    
    public func registerThisDevice(apns:String, completion:(success: Bool, error: NSError?) -> Void) {
        self.apiClient.registerDevice(apns, name: nil, deviceID: nil) {[weak self] (device, error) -> Void in
            if let newDevice = device {
                self?.storage.saveThisDevice(newDevice)
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[weak self] () -> Void in
            guard let device = self?.storage.thisDevice() else {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    
                    completion(success: false, error:NSError.chatSecureError(PushError.noPushDevice, userInfo: nil))
                })
                return
            }
            
            guard let id = device.id else {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error:NSError.chatSecureError(PushError.noPushDevice, userInfo: nil))
                })
                return
            }
            
            self?.apiClient.updateDevice(id, APNSToken: apns, name: device.name, deviceID: device.id, completion: {[weak self] (device, error) -> Void in
                if let newDevice = device {
                    self?.storage.saveThisDevice(newDevice)
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
    
    public func getPubsubEndpoint(completion:(endpoint:String?,error:NSError?) -> Void) {
        if let pubsubEndpoint = pubsubEndpoint {
            self.callbackQueue.addOperationWithBlock({ 
                completion(endpoint: pubsubEndpoint as String, error: nil)
            })
            return
        }
        self.apiClient.getPubsubEndpoint { (pubsubEndpoint, error) in
            self.pubsubEndpoint = pubsubEndpoint
            self.callbackQueue.addOperationWithBlock({
                completion(endpoint: pubsubEndpoint, error: error)
            })
        }
    }
    
    public func getMessagesEndpoint() -> NSURL {
        return self.apiClient.messageEndpont()
    }
    
    public func getNewPushToken(buddyKey:String?, completion:(token:TokenContainer?,error:NSError?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[weak self] () -> Void in
            guard let tokenContainer = self?.storage.unusedToken() else {
                self?.updateUnusedTokenStore({[weak self] (success, error) -> Void in
                    if success {
                        self?.getNewPushToken(buddyKey, completion: completion)
                    } else {
                        self?.callbackQueue.addOperationWithBlock({ () -> Void in
                            completion(token: nil, error: error)
                        })
                    }
                    })
                return
            }
            
            self?.storage.removeUnusedToken(tokenContainer)
            if let buddyKey = buddyKey {
                self?.storage.associateBuddy(tokenContainer, buddyKey: buddyKey)
            }
            self?.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(token: tokenContainer, error: nil)
            })
        }
    }
    
    private func fetchNewPushToken(deviceID:String, name: String?, completion:(success:Bool,error:NSError?)->Void) {
        self.apiClient.createToken(deviceID, name: name) {[weak self] (token, error) -> Void in
            if let newToken = token {
                let tokenContainer = TokenContainer()
                tokenContainer.pushToken = newToken
                self?.storage.saveUnusedToken(tokenContainer)
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[weak self] () -> Void in
            guard let id = self?.storage.thisDevice()?.id else {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: NSError.chatSecureError(PushError.noPushDevice, userInfo: nil))
                })
                return;
            }
            
            var tokensToCreate:UInt = 0
            
            guard let unusedTokens = self?.storage.numberUnusedTokens() else {
                return;
            }
            
            guard let minimumCount = self?.storage.unusedTokenStoreMinimum() else {
                return;
            }
            
            if unusedTokens < minimumCount  {
                tokensToCreate = minimumCount
            }
            
            //If we have less than minimumCount unused tokens left we need to refetch another batch.
            var error:NSError? = nil
            if tokensToCreate > 0 {
                
                let group = dispatch_group_create()
                for _ in 1...tokensToCreate {
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[weak self] () -> Void in
            guard let endpointURL = NSURL(string: endpoint) else  {
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: NSError.chatSecureError(PushError.invalidURL, userInfo: nil))
                })
                return
            }
            
            let token = Token(tokenString: tokenString, type: .unknown, deviceID: nil)
            
            let tokenContainer = TokenContainer()
            tokenContainer.pushToken = token
            tokenContainer.endpoint = endpointURL
            tokenContainer.buddyKey = buddyKey
            self?.storage.saveUsedToken(tokenContainer)
            self?.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(success: true, error: nil)
            })
        }
        
    }
    
    public func tokensForBuddy(buddyKey:String, createdByThisAccount:Bool, transaction:YapDatabaseReadTransaction) throws -> [TokenContainer] {
        guard let buddy = transaction.objectForKey(buddyKey, inCollection: OTRBuddy.collection()) as? OTRBuddy else {
            throw NSError.chatSecureError(PushError.noBuddyFound, userInfo: nil)
        }
        
        var tokens: [TokenContainer] = []
        if let relationshipTransaction = transaction.ext(DatabaseExtensionName.RelationshipExtensionName.name()) as? YapDatabaseRelationshipTransaction {
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
    
    //MARK: Receiving remote notification
    public func receiveRemoteNotification(notification: [NSObject : AnyObject], completion:(buddy:OTRBuddy?, error: NSError?) -> Void) {
        do {
            let message = try Deserializer.messageFromPushDictionary(notification)
            guard let buddy = self.storage.buddy(message.token) else {
                self.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(buddy:nil, error:NSError.chatSecureError(PushError.noBuddyFound, userInfo: nil))
                })
                return;
            }
            
            self.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(buddy: buddy, error: nil)
            })
            
            
            
            
        } catch let error as NSError{
            self.callbackQueue.addOperationWithBlock({ () -> Void in
                completion(buddy: nil, error: error)
            })
        }
    }

    //MARK: Sending Message
    public func sendKnock(buddyKey:String, completion:(success:Bool, error:NSError?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[weak self] () -> Void in
            do {
                guard let token = try self?.storage.tokensForBuddy(buddyKey, createdByThisAccount: false).first else {
                    self?.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: false, error: NSError.chatSecureError(PushError.noTokensFound, userInfo: nil))
                    })
                    return
                }
                
                guard let tokenString = token.pushToken?.tokenString else {
                    self?.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: false, error: NSError.chatSecureError(PushError.noTokensFound, userInfo: nil))
                    })
                    return
                }
                
                guard let url = token.endpoint else {
                    self?.callbackQueue.addOperationWithBlock({ () -> Void in
                        completion(success: false, error: NSError.chatSecureError(PushError.missingAPIEndpoint, userInfo: nil))
                    })
                    return
                }
                
                let message = Message(token: tokenString, url:url , data: nil)
                
                self?.apiClient.sendMessage(message, completion: {[weak self] (message, error) -> Void in
                    
                    if (error?.code == 404) {
                        // Token was revoked or was never valid.
                        self?.storage.removeToken(token)
                        // Retry and see if we have another token to use or will error out with noTokensFound
                        self?.sendKnock(buddyKey, completion: completion)
                    }
                    else if let _ = message {
                        self?.callbackQueue.addOperationWithBlock({ () -> Void in
                            completion(success: true, error: nil)
                        })
                    } else {
                        self?.callbackQueue.addOperationWithBlock({ () -> Void in
                            completion(success: false, error: error)
                        })
                    }
                })
            } catch let error as NSError {
                
                self?.callbackQueue.addOperationWithBlock({ () -> Void in
                    completion(success: false, error: error)
                })
            }
        }
    }
    
    
    //MARK: APNS Token
    public func didRegisterForRemoteNotificationsWithDeviceToken(data:NSData) -> Void {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {[weak self] () -> Void in
            let pushTokenString = data.hexString;
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
    public func receivePushData(tlvData: NSData!, username: String!, accountName: String!, protocolString: String!, fingerprint:OTRFingerprint!) {
        
        let buddy = self.storage.buddy(username, accountName: accountName)
        
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
                let account = self.storage.account(buddy!.accountUniqueId)
                if account?.accountType == OTRAccountType.XMPPTor {
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
    
    public static func getPushPreference() -> PushPreference {
        guard let value = NSUserDefaults.standardUserDefaults().valueForKey(kOTRPushEnabledKey)?.boolValue else {
            return PushPreference.Undefined
        }
        if value {
            return PushPreference.Enabled
        } else {
            return PushPreference.Disabled
        }
    }
    
    public static func setPushPreference(preference: PushPreference) {
        var bool = false
        if preference == .Enabled {
            bool = true
        }
        NSUserDefaults.standardUserDefaults().setBool(bool, forKey: kOTRPushEnabledKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    //MARK: Utility
    
    /// If callbackQueue is nil, it will complete on main queue
    public func gatherPushInfo(completion: (PushInfo) -> (), callbackQueue: dispatch_queue_t?) {
        var pubsubEndpoint: String?
        var pushPermitted = false
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        pushPermitted = PushController.canReceivePushNotifications() // This will be async in a later version when we do iOS 10 refactor
        dispatch_group_enter(group)
        dispatch_group_leave(group)
        getPubsubEndpoint { (endpoint, error) in
            pubsubEndpoint = endpoint
            dispatch_group_leave(group)
        }
        var queue = dispatch_get_main_queue()
        if let custom = callbackQueue {
            queue = custom
        }
        let device = storage.thisDevice()
        dispatch_group_notify(group, queue) {
            let newPushInfo = PushInfo(
                pushAPIURL: self.apiClient.baseUrl,
                hasPushAccount: self.storage.hasPushAccount(),
                numUsedTokens: self.storage.numberUsedTokens(),
                numUnusedTokens: self.storage.numberUnusedTokens(),
                pushPermitted: pushPermitted,
                pubsubEndpoint: pubsubEndpoint,
                device: device)
            completion(newPushInfo)
        }
    }
    
    public static func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.currentNotificationCenter()
            center.requestAuthorizationWithOptions([.Badge, .Alert, .Sound], completionHandler: { (granted, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    // TODO: Handle push registration error
                    let app = UIApplication.sharedApplication()
                    NSNotificationCenter.defaultCenter().postNotificationName(OTRUserNotificationsChanged, object: app.delegate, userInfo:nil)
                    if (granted) {
                        app.registerForRemoteNotifications()
                    }
                })
            })
        } else {
            let notificationSettings = UIUserNotificationSettings(forTypes: [.Badge, .Alert, .Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        }
    }
    
    public static func canReceivePushNotifications() -> Bool {
        var isEnabled = false
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            isEnabled = settings.types != .None
        }
        return isEnabled
        // Making this function async to satisfy the iOS 10 way is extremely difficult due to how OTRSettingsManager.populateSettings works
        /*
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.currentNotificationCenter()
            center.getNotificationSettingsWithCompletionHandler({ (settings: UNNotificationSettings) in
                let isEnabled = settings.authorizationStatus != .Authorized
                dispatch_async(dispatch_get_main_queue(), {
                    completion(canReceive: isEnabled)
                })
            })
        } else {
            var isEnabled = false
            if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
                isEnabled = settings.types != .None
            }
            dispatch_async(dispatch_get_main_queue(), {
                completion(canReceive: isEnabled)
            })
        }
         */
    }
}
