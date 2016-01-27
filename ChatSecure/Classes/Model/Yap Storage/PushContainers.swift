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

public class DeviceContainer: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    var pushDevice:Device?
    var pushAccountKey:String?
    
    
    
    override public var uniqueId:String {
        get {
            if let id = self.pushDevice?.id {
                return id
            } else {
                return super.uniqueId
            }
        }
    }
    
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        if let accountKey = self.pushAccountKey {
            let accountEdge = YapDatabaseRelationshipEdge(name: kDeviceAccountRelationshipEdgeName, destinationKey: accountKey, collection: Account.yapCollection(), nodeDeleteRules: YDB_NodeDeleteRules())
            return [accountEdge]
        }
        return nil
    }
}

public class TokenContainer: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    var pushToken:Token?
    var date = NSDate()
    var accountKey: String?
    var buddyKey: String?
    var endpoint:NSURL?
    
    override public var uniqueId:String {
        get {
            if let id = self.pushToken?.tokenString {
                return id
            } else {
                return super.uniqueId
            }
        }
    }
    
    public func yapDatabaseRelationshipEdges() -> [YapDatabaseRelationshipEdge]? {
        var edges:[YapDatabaseRelationshipEdge] = []
        if let buddyKey = self.buddyKey {
            let buddyEdge = YapDatabaseRelationshipEdge(name: kBuddyTokenRelationshipEdgeName, destinationKey: buddyKey, collection: OTRBuddy.collection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)
            edges.append(buddyEdge)
        }
        
        if let accountKey = self.accountKey {
            let accountEdge = YapDatabaseRelationshipEdge(name: kBuddyTokenRelationshipEdgeName, destinationKey: accountKey, collection: Account.yapCollection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)
            edges.append(accountEdge)
        }
        
        
        return edges
    }
    
}