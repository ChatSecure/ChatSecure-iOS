//
//  OTRYapViewHandler.swift
//  ChatSecure
//
//  Created by David Chiles on 10/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

@objc public protocol OTRYapViewHandlerDelegateProtocol:NSObjectProtocol {
    
    optional func didRecieveChanges(handler:OTRYapViewHandler, sectionChanges:[YapDatabaseViewSectionChange], rowChanges:[YapDatabaseViewRowChange])
    optional func didReceiveChanges(handler:OTRYapViewHandler, key:String, collection:String)
}

public struct keyCollectionPair {
    public let key:String
    public let collection:String
    
    public init(key:String, collection:String){
        self.key = key
        self.collection = collection
    }
}

public class OTRYapKeyCollectionHandler {
    
    var storage = Dictionary<String, keyCollectionPair>()
    
    public func observe(key:String, collection:String) {
        let k = key + collection
        storage.updateValue(keyCollectionPair(key: key, collection: collection), forKey: k)
    }
    
    public func stopObserving(key:String, collection:String) {
        let k = key + collection
        storage.removeValueForKey(k)
    }
}


public class OTRYapViewHandler: NSObject {
    
    var notificationToken:NSObjectProtocol? = nil
    public weak var delegate:OTRYapViewHandlerDelegateProtocol? = nil
    public let keyCollectionObserver = OTRYapKeyCollectionHandler()
    
    public var mappings:YapDatabaseViewMappings? {
        didSet {
            self.databaseConnection.readWithBlock { (transaction) -> Void in
                self.mappings?.updateWithTransaction(transaction)
            }
        }
    }
    
    public var databaseConnection:YapDatabaseConnection {
        didSet {
            self.setupDatabseConnection()
        }
    }
    
    public init(databaseConnection:YapDatabaseConnection) {
        self.databaseConnection = databaseConnection
        super.init()
        self.setupDatabseConnection()
    }
    
    deinit {
        if let token = self.notificationToken {
            NSNotificationCenter.defaultCenter().removeObserver(token)
        }
    }
    
    func setupDatabseConnection() {
        self.databaseConnection.beginLongLivedReadTransaction()
        self.notificationToken = NSNotificationCenter.defaultCenter().addObserverForName(YapDatabaseModifiedNotification, object: self.databaseConnection.database, queue: NSOperationQueue.mainQueue()) {[weak self] (notification) -> Void in
            self?.yapDatbaseModified(notification)
        }
    }
    
    public func setup(view:String,groups:[String]) {
        self.mappings  = YapDatabaseViewMappings(groups: groups, view: view)
    }
    
    public func object(indexPath:NSIndexPath) -> AnyObject? {
        var object:AnyObject? = nil
        self.databaseConnection .readWithBlock { (transaction) -> Void in
            guard let viewName = self.mappings?.view else {
                return
            }
            
            guard let viewTransaction:YapDatabaseViewTransaction = (transaction.ext(viewName) as? YapDatabaseViewTransaction) else {
                return
            }
            
            let row = UInt(indexPath.row)
            let section = UInt(indexPath.section)
            
            if(row < self.mappings?.numberOfItemsInSection(section)) {
                object = viewTransaction.objectAtRow(row, inSection: section, withMappings: self.mappings)
            }
        }
        
        return object;
    }
    
    func yapDatbaseModified(notification:NSNotification) {
        let notifications = self.databaseConnection.beginLongLivedReadTransaction()
        
        guard let viewName = self.mappings?.view else {
            return
        }
        
        guard let databaseView = self.databaseConnection.ext(viewName) as? YapDatabaseViewConnection else {
            return
        }
        
        var sectionChanges:NSArray? = nil
        var rowChanges:NSArray? = nil
        
        databaseView.getSectionChanges(&sectionChanges, rowChanges: &rowChanges, forNotifications: notifications, withMappings: self.mappings)

        if let sc = sectionChanges as? [YapDatabaseViewSectionChange] {
            if let rc = rowChanges as? [YapDatabaseViewRowChange] {
                if sc.count > 0 || rc.count > 0 {
                    self.delegate?.didRecieveChanges?(self, sectionChanges: sc, rowChanges: rc)
                }
            }
        }
        
        for (_,value) in self.keyCollectionObserver.storage {
            if self.databaseConnection.hasChangeForKey(value.key, inCollection: value.collection, inNotifications: notifications) {
                self.delegate?.didReceiveChanges?(self, key: value.key, collection: value.collection)
            }
        }
    }
}

