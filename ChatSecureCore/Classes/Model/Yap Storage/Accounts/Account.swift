//
//  Account.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 12/3/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

extension OTRAccount {
    public func lastMessage(with transaction: YapDatabaseReadTransaction) -> OTRMessageProtocol? {
        guard let buddyTransaction = transaction.ext(OTRBuddyFilteredConversationsName) as? YapDatabaseFilteredViewTransaction,
        let lastBuddy = buddyTransaction.lastObject(inGroup: OTRConversationGroup) as? OTRBuddy,
        let lastMessage = lastBuddy.lastMessage(with: transaction) else {
            return nil
        }
        return lastMessage
    }
}
