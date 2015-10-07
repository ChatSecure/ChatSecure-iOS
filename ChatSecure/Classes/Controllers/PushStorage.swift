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

public protocol PushStorageProtocol: class {
    func thisDevicePushAccount() -> Account?
    func hasPushAccount() -> Bool
    func saveThisAccount(account:Account)
    func thisDevice() -> Device?
    func saveThisDevice(device:Device)
    func unusedToken() -> TokenContainer?
    func removeUnusedToken(token: TokenContainer)
    func associateBuddy(tokenContainer:TokenContainer, buddyKey:String)
    func saveUnusedToken(tokenContainer:TokenContainer)
    func saveUsedToken(tokenContainer:TokenContainer)
    func numberUnusedTokens() -> UInt
    func unusedTokenStoreMinimum() -> UInt
    func tokensForBuddy(buddyKey:String, createdByThisAccount:Bool) throws -> [TokenContainer]
    func buddy(username: String, accountName: String) -> OTRBuddy?
    func account(accountUniqueID:String) -> OTRAccount?
    func budy(token:String) -> OTRBuddy?
}

extension Account {
    public class func yapCollection() -> String {
        return "ChatSecurePushAccountColletion"
    }
}

class PushStorage: NSObject, PushStorageProtocol {
    
    let databaseConnection: YapDatabaseConnection
    
    static let unusedTokenStoreSize:UInt = 50
    
    enum PushYapKeys: String {
        case thisDeviceKey = "kYapThisDeviceKey"
        case thisAccountKey = "kYapThisAccountKey"
    }
    
    enum PushYapCollections: String {
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
        self.databaseConnection.readWriteWithBlock { (transaction) -> Void in
            transaction.setObject(account, forKey:PushYapKeys.thisAccountKey.rawValue, inCollection:Account.yapCollection())
        }
    }
    
    func saveThisDevice(device: Device) {
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
        self.databaseConnection.readWriteWithBlock { (transaction) -> Void in
            transaction.removeObjectForKey(token.uniqueId, inCollection: PushYapCollections.unusedTokenCollection.rawValue)
        }
    }
    
    func associateBuddy(tokenContainer: TokenContainer, buddyKey: String) {
        self.databaseConnection.readWriteWithBlock { (transaction) -> Void in
            tokenContainer.buddyKey = buddyKey
            tokenContainer.saveWithTransaction(transaction)
        }
    }
    
    func saveUnusedToken(tokenContainer: TokenContainer) {
        self.databaseConnection.readWriteWithBlock { (transaction) -> Void in
            tokenContainer.accountKey = PushYapKeys.thisAccountKey.rawValue
            transaction.setObject(tokenContainer, forKey:tokenContainer.uniqueId, inCollection:PushYapCollections.unusedTokenCollection.rawValue)
        }
    }
    
    func saveUsedToken(tokenContainer: TokenContainer) {
        self.databaseConnection.readWriteWithBlock { (transaction) -> Void in
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
        self.databaseConnection.readWriteWithBlock { (transaction) -> Void in
            guard let buddy = transaction.objectForKey(buddyKey, inCollection: OTRBuddy.collection()) as? OTRBuddy else {
                error = PushError.noBuddyFound.error()
                return
            }
            
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
        }
        if let err = error {
            throw err
        }
        return tokens
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
    
    func budy(token: String) -> OTRBuddy? {
        var buddy:OTRBuddy? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            if let relationshipTransaction = transaction.ext(OTRYapDatabaseRelationshipName) as? YapDatabaseRelationshipTransaction {
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
