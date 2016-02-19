//
//  OTRYapViewHandler.swift
//  ChatSecure
//
//  Created by David Chiles on 10/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase.YapDatabaseView

@objc public protocol OTRYapViewHandlerDelegateProtocol:NSObjectProtocol {
    
    /** Recommeded to do a reload data here*/
    optional func didSetupMappings(handler:OTRYapViewHandler)
    optional func didReceiveChanges(handler:OTRYapViewHandler, sectionChanges:[YapDatabaseViewSectionChange], rowChanges:[YapDatabaseViewRowChange])
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

public class OTRYapKeyCollectionHandler:NSObject {
    
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
    public var viewName:String? = nil
    public var groups:[String]? = nil
    public weak var delegate:OTRYapViewHandlerDelegateProtocol? = nil
    public let keyCollectionObserver = OTRYapKeyCollectionHandler()
    
    public var mappings:YapDatabaseViewMappings? {
        didSet {
            self.databaseConnection.asyncReadWithBlock { (transaction) -> Void in
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
        self.viewName = view
        self.groups = groups
        self.mappings = nil;
        self.setupMappings(view, groups: groups);
    }
    
    func setupMappings(view:String,groups:[String]) {
        self.databaseConnection.asyncReadWithBlock({ (transaction) -> Void in
            if let _ = transaction.ext(view) {
                self.mappings  = YapDatabaseViewMappings(groups: groups, view: view)
            }
            }, completionQueue: dispatch_get_main_queue()) { () -> Void in
                if(self.mappings != nil) {
                    self.delegate?.didSetupMappings?(self)
                }
        }
    }
    
    public func object(indexPath:NSIndexPath) -> AnyObject? {
        var object:AnyObject? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            guard let viewName = self.mappings?.view else {
                return
            }
            
            guard let viewTransaction:YapDatabaseViewTransaction = (transaction.ext(viewName) as? YapDatabaseViewTransaction) else {
                return
            }
            
            let row = UInt(indexPath.row)
            let section = UInt(indexPath.section)
            
            if let mappings = self.mappings where row < mappings.numberOfItemsInSection(section) {
                object = viewTransaction.objectAtRow(row, inSection: section, withMappings: mappings)
            }
        }
        
        return object;
    }
    
    func yapDatbaseModified(notification:NSNotification) {
        let notifications = self.databaseConnection.beginLongLivedReadTransaction()
        
        //There are no mappings so we need to set them up first
        guard let mappings = self.mappings else {
            if let view = self.viewName {
                if let groups = self.groups {
                    self.setupMappings(view, groups: groups);
                }
            }
            return
        }
        
        guard let databaseView = self.databaseConnection.ext(mappings.view) as? YapDatabaseViewConnection else {
            return
        }
        
        var sectionChanges:NSArray? = nil
        var rowChanges:NSArray? = nil
        
        databaseView.getSectionChanges(&sectionChanges, rowChanges: &rowChanges, forNotifications: notifications, withMappings: mappings)

        if let sc = sectionChanges as? [YapDatabaseViewSectionChange] {
            if let rc = rowChanges as? [YapDatabaseViewRowChange] {
                if sc.count > 0 || rc.count > 0 {
                    self.delegate?.didReceiveChanges?(self, sectionChanges: sc, rowChanges: rc)
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

