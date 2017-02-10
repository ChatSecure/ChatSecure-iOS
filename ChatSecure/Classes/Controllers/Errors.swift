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
    class func XMPPXMLError(error:OTRXMPPXMLError, userInfo:[String:AnyObject]?) -> NSError {
        return self.chatSecureError(error, userInfo: userInfo)
    }
    
    class func chatSecureError(error:ChatSecureErrorProtocol, userInfo:[String:AnyObject]?) -> NSError {
        var tempUserInfo:[String:AnyObject] = [NSLocalizedDescriptionKey:error.localizedDescription()]
        
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
    case UnableToCreateOTRSession = 350
    case OMEMONotSuported         = 351
}

extension EncryptionError: ChatSecureErrorProtocol {
    func localizedDescription() -> String {
        switch self {
        case UnableToCreateOTRSession: return "Unable to create OTR session"
        case .OMEMONotSuported: return "OMEMO not supported"
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
    case UnkownError     = 1000
    case Conflict        = 1001
    case NotAcceptable   = 1002
    case PolicyViolation = 1003
}

extension OTRXMPPXMLError: ChatSecureErrorProtocol {
    public func code() -> Int {
        return self.rawValue
    }
    
    public func localizedDescription() -> String {
        switch self {
        case .UnkownError:
            return "Unknown Error"
        case .Conflict:
            return "There's a conflict with the username"
        case .NotAcceptable:
            return "Not enough information provided"
        case .PolicyViolation:
            return "Server policy violation"
        }
    }
    
    public func additionalUserInfo() -> [String : AnyObject]? {
        return nil
    }
}

@objc public enum OTROMEMOError: Int {
    case UnknownError      = 1100
    case NoDevicesForBuddy = 1101
    case NoDevices         = 1102
}

extension OTROMEMOError: ChatSecureErrorProtocol {
    public func code() -> Int {
        return self.rawValue
    }
    
    public func localizedDescription() -> String {
        switch self {
        case .UnknownError:
            return UNKNOWN_ERROR_STRING()
        case .NoDevicesForBuddy:
            return NO_DEVICES_BUDDY_ERROR_STRING()
        case .NoDevices:
            return NO_DEVICES_ACCOUNT_ERROR_STRING()
        }
    }
    
    
    public func additionalUserInfo() -> [String : AnyObject]? {
        return nil
    }
}
