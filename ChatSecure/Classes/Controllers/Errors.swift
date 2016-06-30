//
//  Errors.swift
//  ChatSecure
//
//  Created by David Chiles on 9/23/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation

protocol ErrorDescription {
    func localizedDescription() -> String
    func code() -> Int
}

/** Convert our enum error types to NSError using the ErrorDescription protocol */
func convertError<T where T: ErrorDescription>(item:T) -> NSError {
    return NSError(domain: kOTRErrorDomain, code: item.code(), userInfo: [NSLocalizedDescriptionKey:item.localizedDescription()])
}

/** Error types for the Push server*/
enum PushError: Int {
    case noPushDevice       = 301
    case invalidURL         = 302
    case noBuddyFound       = 303
    case noTokensFound      = 304
    case invalidJSON        = 305
    case missingAPIEndpoint = 306
    case missingTokens      = 307
}

extension PushError: ErrorDescription {
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
        case .invalidJSON:
            return "Invalid JSON format."
        case .missingAPIEndpoint:
            return "Missing API endpoint key."
        case .missingTokens:
            return "Missing token key"
        }
    }
    
    func code() -> Int {
        return self.rawValue
    }
}

/** Error types for encryption*/
enum EncryptionError: Int {
    case unableToCreateOTRSession = 350
}

extension EncryptionError: ErrorDescription {
    func localizedDescription() -> String {
        switch self {
        case .unableToCreateOTRSession:
            return "Unable to create OTR session"
        }
    }
    
    func code() -> Int {
        return self.rawValue
    }
}
