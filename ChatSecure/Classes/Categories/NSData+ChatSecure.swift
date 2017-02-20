//
//  NSData+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 2/16/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation


public extension NSData {
    @objc public func hexString() -> String {
        return (self as Data).hexString()
    }
}
