//
//  OTRAccountDatabaseCount.swift
//  ChatSecure
//
//  Created by David Chiles on 1/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

@objc public protocol OTRAccountDatabaseCountDelegate: NSObjectProtocol {
    func accountCountChanged(counter:OTRAccountDatabaseCount)
}

@objc public class OTRAccountDatabaseCount: NSObject
{
    public var databaseConnection:YapDatabaseConnection {
        return self.viewHandler.databaseConnection
    }
    
    public var numberOfAccounts:UInt {
        return self.viewHandler.mappings?.numberOfItemsInAllGroups() ?? 0
    }
    
    public weak var delegate:OTRAccountDatabaseCountDelegate?
    
    private let viewHandler:OTRYapViewHandler
    
    public init(databaseConnection:YapDatabaseConnection, delegate:OTRAccountDatabaseCountDelegate?) {
        self.viewHandler = OTRYapViewHandler(databaseConnection: databaseConnection, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
        
        self.delegate = delegate
        
        super.init()
        self.viewHandler.delegate = self
        self.viewHandler.setup(OTRAllAccountDatabaseViewExtensionName, groups:[OTRAllAccountGroup])
    }
}

extension OTRAccountDatabaseCount: OTRYapViewHandlerDelegateProtocol {
    public func didSetupMappings(handler: OTRYapViewHandler) {
        self.delegate?.accountCountChanged(self)
    }
    
    public func didReceiveChanges(handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        self.delegate?.accountCountChanged(self)
    }
}
