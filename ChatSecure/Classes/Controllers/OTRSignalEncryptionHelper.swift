//
//  OTROTRSignalEncryptionHelper.swift
//  ChatSecure
//
//  Created by David Chiles on 10/3/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRKit

class OTRSignalEncryptionHelper {
    
    /**
     Encrypt data with IV and key using aes-128-gcm
     
     - parameter data: The data to be encrypted.
     - parameter key The symmetric key
     - parameter iv The initialization vector
     
     returns: The encrypted data
     */
    class func encryptData(data:NSData, key:NSData, iv:NSData) throws -> NSData? {
        return try OTRCryptoUtility.encryptAESGCMData(data, key: key, iv: iv)
    }
    
    /**
     Decrypt data with IV and key using aes-128-gcm
     
     - parameter data: The data to be decrypted.
     - parameter key The symmetric key
     - parameter iv The initialization vector
     
     returns: The Decrypted data
     */
    class func decryptData(data:NSData, key:NSData, iv:NSData) throws -> NSData? {
        return try OTRCryptoUtility.decryptAESGCMData(data, key: key, iv: iv)
    }
    
    /** Generates random data of length 16 bytes */
    private class func randomDataOfBlockLength() -> NSData? {
        return OTRPasswordGenerator.randomDataWithLength(16)
    }
    
    /** Generates random key of length 16 bytes*/
    class func generateSymmetricKey() -> NSData? {
        return self.randomDataOfBlockLength()
    }
    /** Generates random iv of length 16 bytes */
    class func generateIV() -> NSData? {
        return self.randomDataOfBlockLength()
    }
    
}
