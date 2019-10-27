//
//  PushContainers.swift
//  ChatSecure
//
//  Created by David Chiles on 9/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS
import YapDatabase.YapDatabaseRelationship

let kDeviceAccountRelationshipEdgeName = "OTRPushDeviceAccountRelationshipEdgeName"
let kBuddyTokenRelationshipEdgeName = "OTRPushBuddyTokenRelationshipEdgeName"
let kAccountTokenRelationshipEdgeName = "OTRPushAccountTokenRelationshipEdgeName"

open class DeviceContainer: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    @objc var pushDevice:Device?
    @objc var pushAccountKey:String?
    
    
    
    override open var uniqueId:String {
        get {
            if let id = self.pushDevice?.id {
                return id
            } else {
                return super.uniqueId
            }
        }
    }
    
    open func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        if let accountKey = self.pushAccountKey {
            let accountEdge = YapDatabaseRelationshipEdge(name: kDeviceAccountRelationshipEdgeName, destinationKey: accountKey, collection: Account.yapCollection(), nodeDeleteRules: YDB_NodeDeleteRules())
            return [accountEdge]
        }
        return nil
    }
    
    open override class var supportsSecureCoding: Bool {
        return true
    }
}

open class TokenContainer: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    @objc open var pushToken:Token?
    @objc var date = Date()
    @objc var accountKey: String?
    @objc var buddyKey: String?
    @objc var endpoint:URL?
    
    override open var uniqueId:String {
        get {
            if let id = self.pushToken?.tokenString {
                return id
            } else {
                return super.uniqueId
            }
        }
    }
    
    open func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        var edges:[YapDatabaseRelationshipEdge] = []
        if let buddyKey = self.buddyKey {
            let buddyEdge = YapDatabaseRelationshipEdge(name: kBuddyTokenRelationshipEdgeName, destinationKey: buddyKey, collection: OTRBuddy.collection, nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)
            edges.append(buddyEdge)
        }
        
        if let accountKey = self.accountKey {
            let accountEdge = YapDatabaseRelationshipEdge(name: kBuddyTokenRelationshipEdgeName, destinationKey: accountKey, collection: Account.yapCollection(), nodeDeleteRules: YDB_NodeDeleteRules.deleteSourceIfDestinationDeleted)
            edges.append(accountEdge)
        }
        
        
        return edges
    }
    
    open override class var supportsSecureCoding: Bool {
        return true
    }
}
