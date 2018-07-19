//
//  Compatibility.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 7/15/18.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import Foundation

#if swift(>=4.1)
#elseif swift(>=4.2)
    #warning("Remove this once we've updated.")
#else
    extension Collection {
        func compactMap<ElementOfResult>(
            _ transform: (Element) throws -> ElementOfResult?
            ) rethrows -> [ElementOfResult] {
            return try flatMap(transform)
        }
    }
#endif
