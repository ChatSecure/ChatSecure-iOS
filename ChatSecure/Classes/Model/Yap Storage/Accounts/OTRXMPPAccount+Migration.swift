//
//  OTRAccount+Migration.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-05-11.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

public extension OTRXMPPAccount {

    public var needsMigration: Bool {
        guard let jid = bareJID else { return false }
        if OTRServerDeprecation.isDeprecated(server: jid.domain) {
            if !autologin, let xmpp = OTRProtocolManager.shared.protocol(for: self) as? OTRXMPPManager,
                xmpp.connectionStatus == .disconnected {
                return false // May have migrated
            }
            return !self.isArchived
        }
        return false
    }
}
