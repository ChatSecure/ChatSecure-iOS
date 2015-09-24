//
//  Errors.swift
//  ChatSecure
//
//  Created by David Chiles on 9/23/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation

enum PushError: Int {
    case noPushDevice  = 301
    case invalidURL    = 302
    case noBuddyFound  = 303
    case noTokensFound = 304
}

extension PushError {
    func localizedDescription() -> String {
        switch self {
        case .noPushDevice:
            return "No device found. Need to create device first."
        case .invalidURL:
            return "Invalid URL."
        case .noBuddyFound:
            return "No buddy found."
        case .noTokensFound:
            return "No tokens found."
        }
    }
    
    func error() -> NSError {
        return NSError(domain: kOTRErrorDomain, code: self.rawValue, userInfo: [NSLocalizedDescriptionKey:self.localizedDescription()])
    }
}