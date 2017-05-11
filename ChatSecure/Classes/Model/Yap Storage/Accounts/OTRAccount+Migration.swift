//
//  OTRAccount+Migration.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-05-11.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

public extension OTRAccount {

    public func needsMigration() -> Bool {
        guard let xmppAccount = self as? OTRXMPPAccount, !OTRServerDeprecation.hasMigrated(account: xmppAccount), let jid = xmppAccount.bareJID else { return false }
        if OTRServerDeprecation.isDeprecated(server: jid.domain) {
            if let vCardJid = xmppAccount.vCardTemp.jid, vCardJid.isEqual(to: jid, options: XMPPJIDCompareBare) {
                return false // Already in the migration process
            }
            return true
        }
        return false
    }
    
    public func setHasMigrated(_ migrated:Bool) {
        guard let xmppAccount = self as? OTRXMPPAccount else { return }
        OTRServerDeprecation.setAccount(account: xmppAccount, migrated: migrated)
    }
}
