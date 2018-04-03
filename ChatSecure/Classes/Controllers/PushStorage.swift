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
    func saveThisAccount(_ account:Account)
    func thisDevice() -> Device?
    func saveThisDevice(_ device:Device)
    func unusedToken() -> TokenContainer?
    func removeUnusedToken(_ token: TokenContainer)
    func removeToken(_ token: TokenContainer)
    func associateBuddy(_ tokenContainer:TokenContainer, buddyKey:String)
    func saveUnusedToken(_ tokenContainer:TokenContainer)
    func saveUsedToken(_ tokenContainer:TokenContainer)
    func numberUnusedTokens() -> UInt
    func numberUsedTokens() -> UInt
    func unusedTokenStoreMinimum() -> UInt
    func tokensForBuddy(_ buddyKey:String, createdByThisAccount:Bool) throws -> [TokenContainer]
    func numberOfTokensForBuddy(_ buddyKey:String, createdByThisAccount:Bool) -> Int
    func buddy(_ username: String, accountName: String) -> OTRBuddy?
    func account(_ accountUniqueID:String) -> OTRAccount?
    func buddy(_ token:String) -> OTRBuddy?
    func deleteEverything(completion: (()->())?, callbackQueue: DispatchQueue?)

    /**
     * Asynchronously remvoes all the unused tokens in the unsedTokenCollection that are missing an expires date. This was needed
     * for when we moved from not having expires date to saving expires date in the database. This clears those tokens that have not been
     * given out already.
     *
     * parameter timeBuffer: Destry tokens that expire this far into the future. This allows you to clear out tokens that may
     * expire in the next few hours or days
     * parameter completion: This is called once all the tokens have been removed and the count of total tokens remvoed
    */
    func removeAllOurExpiredUnusedTokens(_ timeBuffer:TimeInterval, completion:((_ count:Int)->Void)?)
}

extension Account {
    public class func yapCollection() -> String {
        return "ChatSecurePushAccountColletion"
    }
}

class PushStorage: NSObject, PushStorageProtocol {
    
    let databaseConnection: YapDatabaseConnection
    let workQueue = DispatchQueue(label: "PushStorage_Work_Queue", attributes: [])
    
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
    
    func thisDevicePushAccount(transaction: YapDatabaseReadTransaction) -> Account? {
        var account:Account? = nil
        account = transaction.object(forKey: PushYapKeys.thisAccountKey.rawValue, inCollection: Account.yapCollection()) as? Account
        return account
    }
    
    func thisDevicePushAccount() -> Account? {
        var account:Account? = nil
        self.databaseConnection.read { (transaction) -> Void in
            account = self.thisDevicePushAccount(transaction: transaction)
        }
        return account
    }
    
    func hasPushAccount() -> Bool {
        var hasAccount = false
        self.databaseConnection.read { (transaction) -> Void in
            hasAccount = transaction.hasObject(forKey: PushYapKeys.thisAccountKey.rawValue, inCollection: Account.yapCollection())
        }
        return hasAccount
    }
    
    func saveThisAccount(_ account: Account) {
        self.databaseConnection.asyncReadWrite { (transaction) -> Void in
            transaction.setObject(account, forKey:PushYapKeys.thisAccountKey.rawValue, inCollection:Account.yapCollection())
        }
    }
    
    /// Callback defaults to main queue
    func deleteEverything(completion: (()->())?, callbackQueue: DispatchQueue?) {
        let collections = [Account.yapCollection(), DeviceContainer.collection, PushYapCollections.unusedTokenCollection.rawValue, TokenContainer.collection]
        self.databaseConnection.asyncReadWrite({ (transaction) -> Void in
            for collection in collections {
                transaction.removeAllObjects(inCollection: collection)
            }
        }, completionQueue: callbackQueue,
           completionBlock: completion)
    }
    
    func saveThisDevice(_ device: Device) {
        let deviceContainer = DeviceContainer()
        deviceContainer?.pushDevice = device
        deviceContainer?.pushAccountKey = PushYapKeys.thisAccountKey.rawValue
        self.databaseConnection.asyncReadWrite({ (transaction) -> Void in
            transaction.setObject(deviceContainer, forKey:PushYapKeys.thisDeviceKey.rawValue, inCollection:DeviceContainer.collection)
        })
    }
    
    func thisDevice() -> Device? {
        var device:Device? = nil
        self.databaseConnection.read { (transaction) -> Void in
            if let deviceContainer = transaction.object(forKey: PushYapKeys.thisDeviceKey.rawValue, inCollection:DeviceContainer.collection) as? DeviceContainer {
                device = deviceContainer.pushDevice
            }
        }
        return device
    }
    
    func unusedToken() -> TokenContainer? {
        var tokenContainer:TokenContainer? = nil
        self.databaseConnection.read { (transaction) -> Void in
            transaction.enumerateKeysAndObjects(inCollection: PushYapCollections.unusedTokenCollection.rawValue, using: { (key, object, stop) -> Void in
                if let tc = object as? TokenContainer {
                    tokenContainer = tc
                }
                stop.initialize(to: true)
            })
        }
        return tokenContainer
    }
    
    func removeUnusedToken(_ token: TokenContainer) {
        self.databaseConnection.asyncReadWrite { (transaction) -> Void in
            transaction.removeObject(forKey: token.uniqueId, inCollection: PushYapCollections.unusedTokenCollection.rawValue)
        }
    }
    
    func removeToken(_ token: TokenContainer) {
        self.databaseConnection.asyncReadWrite { (transaction) -> Void in
            token.remove(with: transaction)
        }
    }
    
    func associateBuddy(_ tokenContainer: TokenContainer, buddyKey: String) {
        self.databaseConnection.asyncReadWrite { (transaction) -> Void in
            tokenContainer.buddyKey = buddyKey
            tokenContainer.save(with: transaction)
        }
    }
    
    func saveUnusedToken(_ tokenContainer: TokenContainer) {
        self.databaseConnection.asyncReadWrite { (transaction) -> Void in
            tokenContainer.accountKey = PushYapKeys.thisAccountKey.rawValue
            transaction.setObject(tokenContainer, forKey:tokenContainer.uniqueId, inCollection:PushYapCollections.unusedTokenCollection.rawValue)
        }
    }
    
    func saveUsedToken(_ tokenContainer: TokenContainer) {
        self.databaseConnection.asyncReadWrite { (transaction) -> Void in
            tokenContainer.save(with: transaction)
        }
    }
    
    func numberUnusedTokens() -> UInt {
        var unusedTokensCount:UInt = 0
        self.databaseConnection.read { (transaction) -> Void in
            unusedTokensCount = transaction.numberOfKeys(inCollection: PushYapCollections.unusedTokenCollection.rawValue)
        }
        return unusedTokensCount
    }
    
    func numberUsedTokens() -> UInt {
        var usedTokensCount:UInt = 0
        self.databaseConnection.read { (transaction) -> Void in
            usedTokensCount = transaction.numberOfKeys(inCollection: TokenContainer.collection)
        }
        return usedTokensCount
    }
    
    func unusedTokenStoreMinimum() -> UInt {
        return PushStorage.unusedTokenStoreSize
    }
    
    func tokensForBuddy(_ buddyKey: String, createdByThisAccount: Bool) throws -> [TokenContainer] {
        var error:NSError? = nil
        var tokens:[TokenContainer] = []
        self.databaseConnection.read { (transaction) -> Void in
            guard let buddy = transaction.object(forKey: buddyKey, inCollection: OTRBuddy.collection) as? OTRBuddy else {
                error = NSError.chatSecureError(PushError.noBuddyFound, userInfo: nil)
                return
            }
            
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
        }
        if let err = error {
            throw err
        }
        return tokens
    }
    
    func removeAllOurExpiredUnusedTokens(_ timeBuffer: TimeInterval, completion: ((_ count: Int) -> Void)?) {
        var count:Int = 0
        self.databaseConnection.asyncReadWrite({ (transaction) in
            let collection = PushYapCollections.unusedTokenCollection.rawValue
            var removeKeyArray:[String] = []
            transaction.enumerateKeysAndObjects(inCollection: collection, using: { (key, object, stop) in
                if let token = object as? TokenContainer {
                    //Check that there is an expires date otherwise remove
                    guard let expiresDate = token.pushToken?.expires else {
                        removeKeyArray.append(token.uniqueId)
                        return
                    }
                    
                    // Check that the date is farther in the future than currentDate + timeBuffer
                    if (Date(timeIntervalSinceNow: timeBuffer).compare(expiresDate) == .orderedDescending ) {
                        removeKeyArray.append(token.uniqueId)
                    }
                }
            })
            
            count = removeKeyArray.count
            transaction.removeObjects(forKeys: removeKeyArray, inCollection: collection)
            
            }, completionQueue: self.workQueue) {
                if let comp = completion {
                    DispatchQueue.main.async(execute: {
                        comp(count)
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
    func numberOfTokensForBuddy(_ buddyKey: String, createdByThisAccount: Bool) -> Int {
        var count = 0
        self.databaseConnection.read { (transaction) -> Void in
            guard let relationshipTransaction = transaction.ext(DatabaseExtensionName.relationshipExtensionName.name()) as? YapDatabaseRelationshipTransaction else {
                return
            }
            relationshipTransaction.enumerateEdges(withName: kBuddyTokenRelationshipEdgeName, destinationKey: buddyKey, collection: OTRBuddy.collection, using: { (edge, stop) -> Void in
                if let tokenContainer = transaction.object(forKey: edge.sourceKey, inCollection: edge.sourceCollection) as? TokenContainer {
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
    
    func buddy(_ username: String, accountName: String) -> OTRBuddy? {
        var buddy:OTRBuddy? = nil
        self.databaseConnection.read { (transaction) -> Void in
            guard let jid = XMPPJID(string: username), let account = OTRAccount.allAccounts(withUsername: accountName, transaction: transaction).first else { return }
            buddy = OTRXMPPBuddy.fetchBuddy(jid: jid, accountUniqueId: account.uniqueId, transaction: transaction)
        }
        return buddy
    }
    
    func account(_ accountUniqueID: String) -> OTRAccount? {
        var account:OTRAccount? = nil
        self.databaseConnection.read { (transaction) -> Void in
            account = OTRAccount.fetchObject(withUniqueID: accountUniqueID, transaction: transaction)
        }
        return account
    }
    
    func buddy(_ token: String) -> OTRBuddy? {
        var buddy:OTRBuddy? = nil
        self.databaseConnection.read { (transaction) -> Void in
            if let relationshipTransaction = transaction.ext(DatabaseExtensionName.relationshipExtensionName.name()) as? YapDatabaseRelationshipTransaction {
                relationshipTransaction.enumerateEdges(withName: kBuddyTokenRelationshipEdgeName, sourceKey: token, collection: TokenContainer.collection, using: { (edge, stop) -> Void in
                    buddy = transaction.object(forKey: edge.destinationKey, inCollection: edge.destinationCollection) as? OTRBuddy
                    if buddy != nil {
                        stop.initialize(to: true)
                    }
                })
            }
        }
        return buddy
    }
    
}
