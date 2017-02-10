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

private enum ViewGroups {
    case Array([String])
    case Block(YapDatabaseViewMappingGroupFilter, YapDatabaseViewMappingGroupSort)
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
    private var groups:ViewGroups? = nil
    public weak var delegate:OTRYapViewHandlerDelegateProtocol? = nil
    public let keyCollectionObserver = OTRYapKeyCollectionHandler()
    
    public var mappings:YapDatabaseViewMappings?
    
    public var databaseConnection:YapDatabaseConnection
    
    public init(databaseConnection:YapDatabaseConnection, databaseChangeNotificationName:String = DatabaseNotificationName.LongLivedTransactionChanges) {
        self.databaseConnection = databaseConnection
        super.init()
        self.notificationToken = NSNotificationCenter.defaultCenter().addObserverForName(databaseChangeNotificationName, object: self.databaseConnection, queue: NSOperationQueue.mainQueue()) {[weak self] (notification) -> Void in
            self?.yapDatbaseModified(notification)
        }
    }
    
    deinit {
        if let token = self.notificationToken {
            NSNotificationCenter.defaultCenter().removeObserver(token)
        }
    }
    
    public func setup(view:String,groups:[String]) {
        self.viewName = view
        let groupsArray = ViewGroups.Array(groups)
        self.groups = groupsArray
        self.mappings = nil;
        self.setupMappings(view, groups: groupsArray);
    }
    
    public func setup(view:String, groupBlock:YapDatabaseViewMappingGroupFilter, sortBlock:YapDatabaseViewMappingGroupSort) {
        self.viewName = view
        let groups = ViewGroups.Block(groupBlock,sortBlock)
        self.groups = groups
        self.mappings = nil
        self.setupMappings(view, groups: groups)
    }
    
    public func groupsArray() -> [String]? {
        guard let groups = self.groups else {
            return nil
        }
        switch groups {
            case .Array(let array): return array
            default: return nil
        }
    }
    
    private func setupMappings(view:String,groups:ViewGroups) {
        
        self.databaseConnection.readWithBlock({ (transaction) in
            // Check if extensions exists. If not then don't setup. https://github.com/yapstudios/YapDatabase/issues/203
            if let _ = transaction.ext(view) {
                switch groups {
                case .Array(let array):
                    self.mappings = YapDatabaseViewMappings(groups: array, view: view)
                case .Block(let filterBlock, let sortBlock):
                    self.mappings = YapDatabaseViewMappings(groupFilterBlock: filterBlock, sortBlock: sortBlock, view: view)
                }
                self.mappings?.updateWithTransaction(transaction)
            }
        })
        if(self.mappings != nil) {
            self.delegate?.didSetupMappings?(self)
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
        guard let notifications = notification.userInfo? [DatabaseNotificationKey.ConnectionChanges] as? [NSNotification] else {
            return
        }
        
        for (_,value) in self.keyCollectionObserver.storage {
            if self.databaseConnection.hasChangeForKey(value.key, inCollection: value.collection, inNotifications: notifications) {
                self.delegate?.didReceiveChanges?(self, key: value.key, collection: value.collection)
            }
        }
        
        guard let mappings = self.mappings else {
            if let view = self.viewName, let groups = self.groups {
                self.setupMappings(view, groups: groups);
            }
            return
        }
        
        guard let databaseView = self.databaseConnection.ext(mappings.view) as? YapDatabaseViewConnection else {
            return
        }
        
        var sectionChanges:NSArray? = nil
        var rowChanges:NSArray? = nil
        
        databaseView.getSectionChanges(&sectionChanges, rowChanges: &rowChanges, forNotifications: notifications, withMappings: mappings)
        
        let sc = sectionChanges as? [YapDatabaseViewSectionChange] ?? [YapDatabaseViewSectionChange]()
        let rc = rowChanges as? [YapDatabaseViewRowChange] ?? [YapDatabaseViewRowChange]()
        
        if sc.count > 0 || rc.count > 0 {
            self.delegate?.didReceiveChanges?(self, sectionChanges: sc, rowChanges: rc)
        }
    }
}

