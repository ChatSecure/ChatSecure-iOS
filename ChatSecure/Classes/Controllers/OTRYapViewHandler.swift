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
    @objc optional func didSetupMappings(_ handler:OTRYapViewHandler)
    @objc optional func didReceiveChanges(_ handler:OTRYapViewHandler, sectionChanges:[YapDatabaseViewSectionChange], rowChanges:[YapDatabaseViewRowChange])
    @objc optional func didReceiveChanges(_ handler:OTRYapViewHandler, key:String, collection:String)
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
    case array([String])
    case block(YapDatabaseViewMappingGroupFilter, YapDatabaseViewMappingGroupSort)
}

public class OTRYapKeyCollectionHandler:NSObject {
    
    var storage = Dictionary<String, keyCollectionPair>()
    
    @objc public func observe(_ key:String, collection:String) {
        let k = key + collection
        storage.updateValue(keyCollectionPair(key: key, collection: collection), forKey: k)
    }
    
    @objc public func stopObserving(_ key:String, collection:String) {
        let k = key + collection
        storage.removeValue(forKey: k)
    }
}


public class OTRYapViewHandler: NSObject {
    
    var notificationToken:NSObjectProtocol? = nil
    @objc public var viewName:String? = nil
    private var groups:ViewGroups? = nil
    @objc public weak var delegate:OTRYapViewHandlerDelegateProtocol? = nil
    @objc public let keyCollectionObserver = OTRYapKeyCollectionHandler()
    
    @objc public var mappings:YapDatabaseViewMappings?
    
    @objc public var databaseConnection:YapDatabaseConnection
    
    @objc public init(databaseConnection:YapDatabaseConnection, databaseChangeNotificationName:String = DatabaseNotificationName.LongLivedTransactionChanges) {
        self.databaseConnection = databaseConnection
        super.init()
        self.notificationToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: databaseChangeNotificationName), object: self.databaseConnection, queue: OperationQueue.main) {[weak self] (notification) -> Void in
            self?.yapDatabaseModified(notification)
        }
    }
    
    deinit {
        if let token = self.notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    @objc public func setup(_ view:String,groups:[String]) {
        self.viewName = view
        let groupsArray = ViewGroups.array(groups)
        self.groups = groupsArray
        self.mappings = nil;
        self.setupMappings(view, groups: groupsArray);
    }
    
    @objc public func setup(_ view:String, groupBlock:@escaping YapDatabaseViewMappingGroupFilter, sortBlock:@escaping YapDatabaseViewMappingGroupSort) {
        self.viewName = view
        let groups = ViewGroups.block(groupBlock,sortBlock)
        self.groups = groups
        self.mappings = nil
        self.setupMappings(view, groups: groups)
    }
    
    @objc public func groupsArray() -> [String]? {
        guard let groups = self.groups else {
            return nil
        }
        switch groups {
            case .array(let array): return array
            default: return nil
        }
    }
    
    private func setupMappings(_ view:String,groups:ViewGroups) {
        
        self.databaseConnection.read({ (transaction) in
            // Check if extensions exists. If not then don't setup. https://github.com/yapstudios/YapDatabase/issues/203
            if let _ = transaction.ext(view) {
                switch groups {
                case .array(let array):
                    self.mappings = YapDatabaseViewMappings(groups: array, view: view)
                case .block(let filterBlock, let sortBlock):
                    self.mappings = YapDatabaseViewMappings(groupFilterBlock: filterBlock, sortBlock: sortBlock, view: view)
                }
                self.mappings?.update(with: transaction)
            }
        })
        if(self.mappings != nil) {
            self.delegate?.didSetupMappings?(self)
        }
    }
    
    @objc public func object(_ indexPath:IndexPath) -> AnyObject? {
        var object:AnyObject? = nil
        self.databaseConnection.read { (transaction) -> Void in
            guard let viewName = self.mappings?.view else {
                return
            }
            
            guard let viewTransaction:YapDatabaseViewTransaction = (transaction.ext(viewName) as? YapDatabaseViewTransaction) else {
                return
            }
            
            let row = UInt(indexPath.row)
            let section = UInt(indexPath.section)
            
            if let mappings = self.mappings, row < mappings.numberOfItems(inSection: section) {
                object = viewTransaction.object(atRow: row, inSection: section, with: mappings) as AnyObject?
            }
        }
        
        return object;
    }
    
    func yapDatabaseModified(_ notification:Notification) {
        guard let notifications = notification.userInfo? [DatabaseNotificationKey.ConnectionChanges] as? [Notification] else {
            return
        }
        
        for (_,value) in self.keyCollectionObserver.storage {
            if self.databaseConnection.hasChange(forKey: value.key, inCollection: value.collection, in: notifications) {
                self.delegate?.didReceiveChanges?(self, key: value.key, collection: value.collection)
            }
        }
        
        guard let mappings = self.mappings else {
            if let view = self.viewName, let groups = self.groups {
                self.setupMappings(view, groups: groups);
            }
            return
        }
        
        if notifications.count == 0 {
            return
        }
        
        guard let databaseView = self.databaseConnection.ext(mappings.view) as? YapDatabaseViewConnection else {
            return
        }
        
        let src = databaseView.otr_getSectionRowChanges(for: notifications, with: mappings)
        
        if src.sectionChanges.count > 0 || src.rowChanges.count > 0 {
            self.delegate?.didReceiveChanges?(self, sectionChanges: src.sectionChanges, rowChanges: src.rowChanges)
        }
    }
}

