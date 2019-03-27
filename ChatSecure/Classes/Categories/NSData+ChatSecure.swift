//
//  NSData+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 2/16/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation


extension NSData {
    @objc public func hexString() -> String {
        return (self as Data).hexString()
    }
}

// http://stackoverflow.com/a/26502285/805882
extension NSString {
    
    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    @objc public func dataFromHex() -> Data? {
        let characters = (self as String)
        var data = Data(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: (self as String), options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else {
            return nil
        }
        
        return data
    }
}
