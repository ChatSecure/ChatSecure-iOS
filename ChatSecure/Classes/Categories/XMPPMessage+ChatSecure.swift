//
//  XMPPMessage+ChatSecure.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 10/18/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

public extension XMPPMessage {
    /// Safely extracts XEP-0359 stanza-id
    @objc public func extractStanzaId(account: OTRXMPPAccount) -> String? {
        let stanzaIds = self.stanzaIds
        guard stanzaIds.count > 0,
        let xmpp = OTRProtocolManager.shared.protocol(for: account) as? OTRXMPPManager,
        xmpp.xmppCapabilities.hasValidStanzaId(self) else {
            return nil
        }
        var byJID: XMPPJID? = nil
        if self.isGroupChatMessage {
            byJID = self.from?.bareJID
        } else {
            byJID = account.bareJID
        }
        if let jid = byJID {
            return stanzaIds[jid]
        }
        return nil
    }
}
