//
//  PushContainers.swift
//  ChatSecure
//
//  Created by David Chiles on 9/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS

let deviceAccountRelationshipEdgeName = "OTRPushDeviceAccountRelationshipEdgeName"
let buddyTokenRelationshipEdgeName = "OTRPushbuddyTokenRelationshipEdgeName"

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
    
    public func yapDatabaseRelationshipEdges() -> [AnyObject]! {
        if let accountKey = self.pushAccountKey {
            let accountEdge = [YapDatabaseRelationshipEdge(name: deviceAccountRelationshipEdgeName, destinationKey: accountKey, collection: Account.yapCollection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)]
            return [accountEdge]
        }
        return []
    }
}

public class TokenContainer: OTRYapDatabaseObject, YapDatabaseRelationshipNode {
    var pushToken:Token?
    let date = NSDate()
    var ownedByYou = true
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
    
    public func yapDatabaseRelationshipEdges() -> [AnyObject]! {
        if let buddyKey = self.buddyKey {
            let accountEdge = YapDatabaseRelationshipEdge(name: buddyTokenRelationshipEdgeName, destinationKey: buddyKey, collection: OTRBuddy.collection(), nodeDeleteRules: YDB_NodeDeleteRules.DeleteSourceIfDestinationDeleted)
            return [accountEdge]
        }
        return []
    }
    
}