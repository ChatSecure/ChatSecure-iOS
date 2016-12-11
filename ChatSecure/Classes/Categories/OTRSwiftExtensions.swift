//
//  OTRSwiftExtensions.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 12/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

private extension String {
    //http://stackoverflow.com/a/34454633/805882
    func splitEvery(n: Int) -> [String] {
        var result: [String] = []
        let chars = Array(characters)
        for index in 0.stride(to: chars.count, by: n) {
            result.append(String(chars[index..<min(index+n, chars.count)]))
        }
        return result
    }
}

public extension NSData {
    /// hex, split every 8 bytes by a space
    public func humanReadableFingerprint() -> String {
        return self.xmpp_hexStringValue().splitEvery(8).joinWithSeparator(" ")
    }
}
