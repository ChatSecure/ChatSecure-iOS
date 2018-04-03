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
    func accountCountChanged(_ counter:OTRAccountDatabaseCount)
}

@objc open class OTRAccountDatabaseCount: NSObject
{
    @objc open var databaseConnection:YapDatabaseConnection {
        return self.viewHandler.databaseConnection
    }
    
    @objc open var numberOfAccounts:UInt {
        return self.viewHandler.mappings?.numberOfItemsInAllGroups() ?? 0
    }
    
    @objc open weak var delegate:OTRAccountDatabaseCountDelegate?
    
    fileprivate let viewHandler:OTRYapViewHandler
    
    @objc public init(databaseConnection:YapDatabaseConnection, delegate:OTRAccountDatabaseCountDelegate?) {
        self.viewHandler = OTRYapViewHandler(databaseConnection: databaseConnection, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
        
        self.delegate = delegate
        
        super.init()
        self.viewHandler.delegate = self
        self.viewHandler.setup(OTRAllAccountDatabaseViewExtensionName, groups:[OTRAllAccountGroup])
    }
}

extension OTRAccountDatabaseCount: OTRYapViewHandlerDelegateProtocol {

    public func didSetupMappings(_ handler: OTRYapViewHandler) {
        self.delegate?.accountCountChanged(self)
    }
    
    public func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        self.delegate?.accountCountChanged(self)
    }
}
