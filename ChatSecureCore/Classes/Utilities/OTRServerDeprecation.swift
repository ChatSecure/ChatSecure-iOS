//
//  OTRServerDeprecation.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-04-20.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

open class OTRServerDeprecation: NSObject {
    @objc open var name:String
    @objc open var domain:String
    @objc open var shutdownDate:Date?
    
    @objc public init(name:String, domain:String, shutdownDate:Date?) {
        self.name = name
        self.domain = domain
        self.shutdownDate = shutdownDate
    }
    
    static let dukgo = OTRServerDeprecation(name:"Dukgo", domain:"dukgo.com", shutdownDate:Date(timeIntervalSince1970: TimeInterval(integerLiteral: 1495065600)))
    static let allDeprecatedServers:[String:OTRServerDeprecation] = [
        dukgo.domain:dukgo,
    ]
    
    @objc public static func isDeprecated(server: String) -> Bool {
        return deprecationInfo(withServer: server) != nil
    }
    
    @objc public static func deprecationInfo(withServer server:String) -> OTRServerDeprecation? {
        return allDeprecatedServers[server.lowercased()];
    }
}
