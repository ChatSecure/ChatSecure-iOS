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
    class func encryptData(_ data:Data, key:Data, iv:Data) throws -> OTRCryptoData? {
        return try OTRCryptoUtility.encryptAESGCMData(data, key: key, iv: iv)
    }
    
    /**
     Decrypt data with IV and key using aes-128-gcm
     
     - parameter data: The data to be decrypted.
     - parameter key The symmetric key
     - parameter iv The initialization vector
     
     returns: The Decrypted data
     */
    class func decryptData(_ data:Data, key:Data, iv:Data, authTag:Data) throws -> Data? {
        let cryptoData = OTRCryptoData(data: data, authTag: authTag)
        return try OTRCryptoUtility.decryptAESGCMData(cryptoData, key: key, iv: iv)
    }
    
    /** Generates random data of length 16 bytes */
    fileprivate class func randomDataOfBlockLength() -> Data? {
        return OTRPasswordGenerator.randomData(withLength: 16)
    }
    
    /** Generates random key of length 16 bytes*/
    class func generateSymmetricKey() -> Data? {
        return self.randomDataOfBlockLength()
    }
    /** Generates random iv of length 16 bytes */
    class func generateIV() -> Data? {
        return self.randomDataOfBlockLength()
    }
    
}
