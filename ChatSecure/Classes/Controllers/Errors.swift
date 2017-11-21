//
//  Errors.swift
//  ChatSecure
//
//  Created by David Chiles on 9/23/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import OTRAssets

public extension NSError {
    @objc class func XMPPXMLError(_ error:OTRXMPPXMLError, userInfo:[String:AnyObject]?) -> NSError {
        return self.chatSecureError(error, userInfo: userInfo)
    }
    
    class func chatSecureError(_ error:ChatSecureErrorProtocol, userInfo:[String:AnyObject]?) -> NSError {
        var tempUserInfo:[String:AnyObject] = [NSLocalizedDescriptionKey:error.localizedDescription() as AnyObject]
        
        if let additionalDictionary = error.additionalUserInfo() {
            additionalDictionary.forEach { tempUserInfo.updateValue($1, forKey: $0) }
        }
        
        //Overwrite out userinfo with provided userinfo dicitonary
        if let additionalDictionary = userInfo {
            additionalDictionary.forEach { tempUserInfo.updateValue($1, forKey: $0) }
        }
        
        return NSError(domain: kOTRErrorDomain, code: error.code(), userInfo: tempUserInfo)
    }
}

public protocol ChatSecureErrorProtocol {
    func code() -> Int
    func localizedDescription() -> String
    func additionalUserInfo() -> [String:AnyObject]?
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
    case misingExpiresDate  = 308
}

extension PushError: ChatSecureErrorProtocol {
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
        case .misingExpiresDate:
            return "Missing expires date"
        }
    }
    
    func code() -> Int {
        return self.rawValue
    }
    
    func additionalUserInfo() -> [String : AnyObject]? {
        return nil
    }
}

/** Error types for encryption*/
enum EncryptionError: Int {
    case unableToCreateOTRSession = 350
    case omemoNotSuported         = 351
}

extension EncryptionError: ChatSecureErrorProtocol {
    func localizedDescription() -> String {
        switch self {
        case .unableToCreateOTRSession: return "Unable to create OTR session"
        case .omemoNotSuported: return "OMEMO not supported"
        }
    }
    
    func code() -> Int {
        return self.rawValue
    }
    
    func additionalUserInfo() -> [String : AnyObject]? {
        return nil
    }
}


@objc public enum OTRXMPPXMLError: Int {
    case unknownError     = 1000
    case conflict        = 1001
    case notAcceptable   = 1002
    case policyViolation = 1003
    case serviceUnavailable = 1004
}

public enum OMEMOBundleError: Error {
    case unknown
    case notFound
    case invalid
    case keyGeneration
}

extension OTRXMPPXMLError: ChatSecureErrorProtocol {
    public func code() -> Int {
        return self.rawValue
    }
    
    public func localizedDescription() -> String {
        switch self {
        case .unknownError:
            return "Unknown Error"
        case .conflict:
            return "There's a conflict with the username"
        case .notAcceptable:
            return "Not enough information provided"
        case .policyViolation:
            return "Server policy violation"
        case .serviceUnavailable:
            return MESSAGE_COULD_NOT_BE_SENT_STRING()
        }
    }
    
    public func additionalUserInfo() -> [String : AnyObject]? {
        return nil
    }
}

@objc public enum OTROMEMOError: Int {
    case unknownError      = 1100
    case noDevicesForBuddy = 1101
    case noDevices         = 1102
}

extension OTROMEMOError: ChatSecureErrorProtocol {
    public func code() -> Int {
        return self.rawValue
    }
    
    public func localizedDescription() -> String {
        switch self {
        case .unknownError:
            return UNKNOWN_ERROR_STRING()
        case .noDevicesForBuddy:
            return NO_DEVICES_BUDDY_ERROR_STRING()
        case .noDevices:
            return NO_DEVICES_ACCOUNT_ERROR_STRING()
        }
    }
    
    
    public func additionalUserInfo() -> [String : AnyObject]? {
        return nil
    }
}
