//
//  OTRServerDeprecation.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-04-20.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

open class OTRServerDeprecation: NSObject {
    open var name:String
    open var domain:String
    open var shutdownDate:Date?
    
    public init(name:String, domain:String, shutdownDate:Date?) {
        self.name = name
        self.domain = domain
        self.shutdownDate = shutdownDate
    }
    
    static let dukgo = OTRServerDeprecation(name:"Dukgo", domain:"dukgo.com", shutdownDate:Date(timeIntervalSince1970: TimeInterval(integerLiteral: 1495065600)))
    static let allDeprecatedServers:[String:OTRServerDeprecation] = [
        dukgo.domain:dukgo,
    ]
    static var migratedJids:[String] = []
    
    open static func isDeprecated(server: String) -> Bool {
        return deprecationInfo(withServer: server) != nil
    }
    
    open static func deprecationInfo(withServer server:String) -> OTRServerDeprecation? {
        return allDeprecatedServers[server.lowercased()];
    }
    
    public static func hasMigrated(account: OTRXMPPAccount) -> Bool {
        guard let bareJid:String = account.bareJID?.bare() else { return false }
        return migratedJids.contains(bareJid)
    }
    
    public static func setAccount(account: OTRXMPPAccount, migrated:Bool) {
        guard let bareJid:String = account.bareJID?.bare() else { return }
        if migrated, !migratedJids.contains(bareJid) {
            migratedJids.append(bareJid)
        } else if !migrated, let idx = migratedJids.index(of: bareJid) {
            migratedJids.remove(at: idx)
        }
    }
}
