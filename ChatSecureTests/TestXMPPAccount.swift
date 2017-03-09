//
//  TestXMPPAccount.swift
//  ChatSecure
//
//  Created by David Chiles on 9/9/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
@testable import ChatSecureCore


class TestXMPPAccount: OTRXMPPAccount {
    
    override class func accountClass(for accountType: OTRAccountType) -> Swift.AnyClass? {
        return self
    }
    
    override class func newResource() -> String {
        return "\(arc4random())"
    }
}
