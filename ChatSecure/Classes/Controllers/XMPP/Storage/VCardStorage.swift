//
//  VCardStorage.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 3/3/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

public class VCardStorage: NSObject {
    let connections: DatabaseConnections
    
    @objc public init(connections: DatabaseConnections) {
        self.connections = connections
    }
    
    /// nil jid returns account's vCard
    /// Opens implicit background read transaction
    private func vCard(jid: XMPPJID? = nil,
                       stream: XMPPStream) -> OTRvCard? {
        guard let myJID = stream.myJID,
        let accountId = stream.accountId else {
            return nil
        }
        return connections.read.fetch {
            self.vCard(jid: jid, myJID: myJID, accountId: accountId, transaction: $0)
        }
    }
    
    /// nil jid returns account's vCard
    private func vCard(jid: XMPPJID? = nil,
                       myJID: XMPPJID,
                       accountId: String,
                       transaction: YapDatabaseReadTransaction) -> OTRvCard? {
        guard let jid = jid else {
            return OTRXMPPAccount.fetchObject(withUniqueID: accountId, transaction: transaction)
        }
        if jid.isEqual(to: myJID, options: .bare) {
            return OTRXMPPAccount.fetchObject(withUniqueID: accountId, transaction: transaction)
        } else {
            return OTRXMPPBuddy.fetchBuddy(jid: jid, accountUniqueId: accountId, transaction: transaction)
        }
    }
}

// MARK: - XMPPvCardAvatarStorage

extension VCardStorage: XMPPvCardAvatarStorage {
    public func photoData(for jid: XMPPJID, xmppStream stream: XMPPStream) -> Data? {
        guard let vCard = vCard(jid: jid, stream: stream) else {
            return nil
        }
        return vCard.avatarData
    }
    
    public func photoHash(for jid: XMPPJID, xmppStream stream: XMPPStream) -> String? {
        guard let vCard = vCard(jid: jid, stream: stream) else {
            return nil
        }
        return vCard.photoHash
    }
    
    
    public func clearvCardTemp(for jid: XMPPJID, xmppStream stream: XMPPStream) {
        guard let myJID = stream.myJID,
            let accountId = stream.accountId else {
                return
        }
        connections.write.asyncReadWrite {
            guard let vCard = self.vCard(jid: jid, myJID: myJID, accountId: accountId, transaction: $0)?.copyAsSelf() else {
                DDLogError("No vCard found for \(jid)")
                return
            }
            vCard.vCardTemp = nil
            vCard.waitingForvCardTempFetch = false
            vCard.lastUpdatedvCardTemp = nil
            vCard.save(with: $0)
        }
    }
}

// MARK: - XMPPvCardTempModuleStorage

extension VCardStorage: XMPPvCardTempModuleStorage {
    public func configure(withParent aParent: XMPPvCardTempModule, queue: DispatchQueue) -> Bool {
        return true
    }
    
    public func vCardTemp(for jid: XMPPJID, xmppStream stream: XMPPStream) -> XMPPvCardTemp? {
        return vCard(jid: jid, stream: stream)?.vCardTemp
    }
    
    public func setvCardTemp(_ vCardTemp: XMPPvCardTemp, for jid: XMPPJID, xmppStream stream: XMPPStream) {
        guard let myJID = stream.myJID,
            let accountId = stream.accountId else {
                return
        }
        connections.write.asyncReadWrite {
            guard let vCard = self.vCard(jid: jid, myJID: myJID, accountId: accountId, transaction: $0)?.copyAsSelf() else {
                DDLogError("No vCard found for \(jid)")
                return
            }
            vCard.vCardTemp = vCardTemp
            vCard.waitingForvCardTempFetch = false
            vCard.lastUpdatedvCardTemp = Date()
            vCard.save(with: $0)
        }
    }
    
    public func myvCardTemp(for stream: XMPPStream) -> XMPPvCardTemp? {
        return vCard(stream: stream)?.vCardTemp
    }
    
    public func shouldFetchvCardTemp(for jid: XMPPJID, xmppStream stream: XMPPStream) -> Bool {
        guard stream.isAuthenticated else {
            return false
        }
        guard let vCard = vCard(jid: jid, stream: stream),
        let lastUpdated = vCard.lastUpdatedvCardTemp else {
            return true
        }
        if vCard.waitingForvCardTempFetch {
            return false
        } else if lastUpdated.timeIntervalSinceNow <= -24*60*60 {
            // Saving is not required due to internal use of in-memory OTRBuddyCache
            //This goes to the cache and does not change the database object.
            vCard.waitingForvCardTempFetch = true
            return true
        } else {
            return false
        }
    }
    
    
}
