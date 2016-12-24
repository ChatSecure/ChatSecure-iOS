//
//  PushStorage.swift
//  ChatSecure
//
//  Created by David Chiles on 9/29/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS
import YapDatabase

@objc public protocol PushStorageProtocol: class {
    func thisDevicePushAccount() -> Account?
    func hasPushAccount() -> Bool
    func saveThisAccount(account:Account)
    func thisDevice() -> Device?
    func saveThisDevice(device:Device)
    func unusedToken() -> TokenContainer?
    func removeUnusedToken(token: TokenContainer)
    func removeToken(token: TokenContainer)
    func associateBuddy(tokenContainer:TokenContainer, buddyKey:String)
    func saveUnusedToken(tokenContainer:TokenContainer)
    func saveUsedToken(tokenContainer:TokenContainer)
    func numberUnusedTokens() -> UInt
    func unusedTokenStoreMinimum() -> UInt
    func tokensForBuddy(buddyKey:String, createdByThisAccount:Bool) throws -> [TokenContainer]
    func numberOfTokensForBuddy(buddyKey:String, createdByThisAccount:Bool) -> Int
    func buddy(username: String, accountName: String) -> OTRBuddy?
    func account(accountUniqueID:String) -> OTRAccount?
    func buddy(token:String) -> OTRBuddy?
    
    /**
     * Asynchronously remvoes all the unused tokens in the unsedTokenCollection that are missing an expires date. This was needed
     * for when we moved from not having expires date to saving expires date in the database. This clears those tokens that have not been
     * given out already.
     *
     * parameter timeBuffer: Destry tokens that expire this far into the future. This allows you to clear out tokens that may
     * expire in the next few hours or days
     * parameter completion: This is called once all the tokens have been removed and the count of total tokens remvoed
    */
    func removeAllOurExpiredUnusedTokens(timeBuffer:NSTimeInterval, completion:((count:Int)->Void)?)
}

extension Account {
    public class func yapCollection() -> String {
        return "ChatSecurePushAccountColletion"
    }
}

class PushStorage: NSObject, PushStorageProtocol {
    
    let databaseConnection: YapDatabaseConnection
    let workQueue = dispatch_queue_create("PushStorage_Work_Queue", DISPATCH_QUEUE_SERIAL)
    
    static let unusedTokenStoreSize:UInt = 5
    
    enum PushYapKeys: String {
        case thisDeviceKey = "kYapThisDeviceKey"
        case thisAccountKey = "kYapThisAccountKey"
    }
    
    enum PushYapCollections: String {
        ///Alternate Collection for tokens before they're 'attached' to a buddy. Just downloaded from the server
        case unusedTokenCollection = "kYapUnusedTokenCollection"
    }
    
    init(databaseConnection:YapDatabaseConnection) {
        self.databaseConnection = databaseConnection
    }
    
    func thisDevicePushAccount() -> Account? {
        var account:Account? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            account = transaction.objectForKey(PushYapKeys.thisAccountKey.rawValue, inCollection: Account.yapCollection()) as? Account
        }
        return account
    }
    
    func hasPushAccount() -> Bool {
        var hasAccount = false
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            hasAccount = transaction.hasObjectForKey(PushYapKeys.thisAccountKey.rawValue, inCollection: Account.yapCollection())
        }
        return hasAccount
    }
    
    func saveThisAccount(account: Account) {
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            transaction.setObject(account, forKey:PushYapKeys.thisAccountKey.rawValue, inCollection:Account.yapCollection())
        }
    }
    
    func saveThisDevice(device: Device) {
        let deviceContainer = DeviceContainer()
        deviceContainer.pushDevice = device
        deviceContainer.pushAccountKey = PushYapKeys.thisAccountKey.rawValue
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock({ (transaction) -> Void in
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
    
    func unusedToken() -> TokenContainer? {
        var tokenContainer:TokenContainer? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            transaction.enumerateKeysAndObjectsInCollection(PushYapCollections.unusedTokenCollection.rawValue, usingBlock: { (key, object, stop) -> Void in
                if let tc = object as? TokenContainer {
                    tokenContainer = tc
                }
                stop.initialize(true)
            })
        }
        return tokenContainer
    }
    
    func removeUnusedToken(token: TokenContainer) {
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            transaction.removeObjectForKey(token.uniqueId, inCollection: PushYapCollections.unusedTokenCollection.rawValue)
        }
    }
    
    func removeToken(token: TokenContainer) {
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            token.removeWithTransaction(transaction)
        }
    }
    
    func associateBuddy(tokenContainer: TokenContainer, buddyKey: String) {
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            tokenContainer.buddyKey = buddyKey
            tokenContainer.saveWithTransaction(transaction)
        }
    }
    
    func saveUnusedToken(tokenContainer: TokenContainer) {
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            tokenContainer.accountKey = PushYapKeys.thisAccountKey.rawValue
            transaction.setObject(tokenContainer, forKey:tokenContainer.uniqueId, inCollection:PushYapCollections.unusedTokenCollection.rawValue)
        }
    }
    
    func saveUsedToken(tokenContainer: TokenContainer) {
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock { (transaction) -> Void in
            tokenContainer.saveWithTransaction(transaction)
        }
    }
    
    func numberUnusedTokens() -> UInt {
        var unusedTokensCount:UInt = 0
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            unusedTokensCount = transaction.numberOfKeysInCollection(PushYapCollections.unusedTokenCollection.rawValue)
        }
        return unusedTokensCount
    }
    
    func unusedTokenStoreMinimum() -> UInt {
        return PushStorage.unusedTokenStoreSize
    }
    
    func tokensForBuddy(buddyKey: String, createdByThisAccount: Bool) throws -> [TokenContainer] {
        var error:NSError? = nil
        var tokens:[TokenContainer] = []
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            guard let buddy = transaction.objectForKey(buddyKey, inCollection: OTRBuddy.collection()) as? OTRBuddy else {
                error = NSError.chatSecureError(PushError.noBuddyFound, userInfo: nil)
                return
            }
            
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
        }
        if let err = error {
            throw err
        }
        return tokens
    }
    
    func removeAllOurExpiredUnusedTokens(timeBuffer: NSTimeInterval, completion: ((count: Int) -> Void)?) {
        var count:Int = 0
        OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.asyncReadWriteWithBlock({ (transaction) in
            let collection = PushYapCollections.unusedTokenCollection.rawValue
            var removeKeyArray:[String] = []
            transaction.enumerateKeysAndObjectsInCollection(collection, usingBlock: { (key, object, stop) in
                if let token = object as? TokenContainer {
                    //Check that there is an expires date otherwise remove
                    guard let expiresDate = token.pushToken?.expires else {
                        removeKeyArray.append(token.uniqueId)
                        return
                    }
                    
                    // Check that the date is farther in the future than currentDate + timeBuffer
                    if (NSDate(timeIntervalSinceNow: timeBuffer).compare(expiresDate) == .OrderedDescending ) {
                        removeKeyArray.append(token.uniqueId)
                    }
                }
            })
            
            count = removeKeyArray.count
            transaction.removeObjectsForKeys(removeKeyArray, inCollection: collection)
            
            }, completionQueue: self.workQueue) {
                if let comp = completion {
                    dispatch_async(dispatch_get_main_queue(), {
                        comp(count: count)
                    })
                }
                
                
        }
    }
    
    /**
     Quicker way of getting just the count of the number of tokens. This method may take a little time because of Yap Relationships
     it iterates over all the relationship edges and counts them.
     
     - parameter buddyKey: The uniqueID or yap key for the buddy
     - parameter createdByThisAccount: A bool to check for the count of tokens created by this account (outgoing) or those created by the buddy (incoming)
     - returns: The number of push tokens
    */
    func numberOfTokensForBuddy(buddyKey: String, createdByThisAccount: Bool) -> Int {
        var count = 0
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            guard let relationshipTransaction = transaction.ext(DatabaseExtensionName.RelationshipExtensionName.name()) as? YapDatabaseRelationshipTransaction else {
                return
            }
            relationshipTransaction.enumerateEdgesWithName(kBuddyTokenRelationshipEdgeName, destinationKey: buddyKey, collection: OTRBuddy.collection(), usingBlock: { (edge, stop) -> Void in
                if let tokenContainer = transaction.objectForKey(edge.sourceKey, inCollection: edge.sourceCollection) as? TokenContainer {
                    if tokenContainer.accountKey != nil && createdByThisAccount {
                        count += 1
                    } else if tokenContainer.accountKey == nil && !createdByThisAccount {
                       count += 1
                    }
                }
            })
        }
        
        return count
    }
    
    func buddy(username: String, accountName: String) -> OTRBuddy? {
        var buddy:OTRBuddy? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            buddy = OTRBuddy.fetchBuddyForUsername(username, accountName: accountName, transaction: transaction)
        }
        return buddy
    }
    
    func account(accountUniqueID: String) -> OTRAccount? {
        var account:OTRAccount? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            account = OTRAccount.fetchObjectWithUniqueID(accountUniqueID, transaction: transaction)
        }
        return account
    }
    
    func buddy(token: String) -> OTRBuddy? {
        var buddy:OTRBuddy? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            if let relationshipTransaction = transaction.ext(DatabaseExtensionName.RelationshipExtensionName.name()) as? YapDatabaseRelationshipTransaction {
                relationshipTransaction.enumerateEdgesWithName(kBuddyTokenRelationshipEdgeName, sourceKey: token, collection: TokenContainer.collection(), usingBlock: { (edge, stop) -> Void in
                    buddy = transaction.objectForKey(edge.destinationKey, inCollection: edge.destinationCollection) as? OTRBuddy
                    if buddy != nil {
                        stop.initialize(true)
                    }
                })
            }
        }
        return buddy
    }
    
}
