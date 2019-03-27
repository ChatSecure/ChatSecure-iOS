//
//  OTRAccount+Migration.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-05-11.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

extension OTRXMPPAccount {
    /// This returns all buddies attached to an account, regardless of trust level
    @objc public static func allBuddies(accountId: String,
                                        transaction: YapDatabaseReadTransaction) -> [OTRXMPPBuddy] {
        let extensionName = YapDatabaseConstants.extensionName(.relationshipExtensionName)
        let edgeName = YapDatabaseConstants.edgeName(.buddyAccountEdgeName)
        guard let relationshipTransaction = transaction.ext(extensionName) as? YapDatabaseRelationshipTransaction else {
            return []
        }
        var buddies: [OTRXMPPBuddy] = []
        relationshipTransaction.enumerateEdges(withName: edgeName, destinationKey: accountId, collection: OTRXMPPAccount.collection) { (edge, stop) in
            if let buddy = OTRXMPPBuddy.fetchObject(withUniqueID: edge.sourceKey, transaction: transaction) {
                buddies.append(buddy)
            }
        }
        return buddies
    }
}

extension OTRXMPPAccount {

    @objc public var needsMigration: Bool {
        guard let jid = bareJID else { return false }
        if OTRServerDeprecation.isDeprecated(server: jid.domain) {
            if !autologin, let xmpp = OTRProtocolManager.shared.protocol(for: self) as? XMPPManager,
                xmpp.loginStatus == .disconnected {
                return false // May have migrated
            }
            return !self.isArchived
        }
        return false
    }
}
