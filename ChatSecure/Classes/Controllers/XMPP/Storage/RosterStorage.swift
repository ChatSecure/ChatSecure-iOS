//
//  RosterStorage.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2018-01-21.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework
import YapDatabase

extension OTRYapDatabaseRosterStorage: XMPPRosterDelegate {
    public func xmppRoster(_ sender: XMPPRoster, didReceiveRosterItem item: DDXMLElement) {
        guard let jidStr = item.attributeStringValue(forName: "jid"), let jid = XMPPJID(string: jidStr), let subscription = item.attributeStringValue(forName: "subscription"), let accountId = sender.accountId, let stream = sender.xmppStream
            else { return }
        
        if(jidStr == stream.myJID?.bare)
        {
            // ignore self buddy
            return;
        }
        
        let ask = item.attributeStringValue(forName: "ask")

        self.connection.asyncReadWrite { (transaction) in
            var buddy = self.fetchBuddy(with: jid, stream: stream, transaction: transaction)
            if subscription == "remove" {
                if let buddy = buddy {
                    buddy.remove(with: transaction)
                }
            } else {
                if buddy == nil {
                    buddy = OTRXMPPBuddy()
                    buddy?.accountUniqueId = accountId
                    
                    // We can be called with buddies that are not really on our roster, i.e.
                    // they are in state none + pendingIn, so default to BuddyTrustLevelUntrusted and set to BuddyTrustLevelRoster only when we are subscribed to them.
                    buddy?.trustLevel = .untrusted;
                    buddy?.displayName = jid.user ?? jidStr
                    buddy?.username = jid.bare
                } else {
                    buddy = buddy?.copyAsSelf()
                }
                guard let buddy = buddy else { return }
                buddy.subscription = SubscriptionAttribute(rawValue: subscription) ?? .none
                buddy.pending.setPendingOut(pending: (ask == "subscribe"))
                if buddy.subscribedFrom {
                    buddy.pending.setPendingIn(pending: false)
                }
                if buddy.subscribedTo || buddy.subscribedFrom {
                    buddy.trustLevel = .roster
                }
                
                // Update name
                if let name = item.attributeStringValue(forName: "name"), name.count > 0 {
                    buddy.displayName = name
                }
                
                buddy.save(with: transaction)
            }
        }
    }
}
