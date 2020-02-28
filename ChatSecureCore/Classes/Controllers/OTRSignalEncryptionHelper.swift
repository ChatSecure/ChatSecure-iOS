//
//  OTROTRSignalEncryptionHelper.swift
//  ChatSecure
//
//  Created by David Chiles on 10/3/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRKit
import CryptoKit

class OTRSignalEncryptionHelper {
    
    /**
     Encrypt data with IV and key using aes-128-gcm
     
     - parameter data: The data to be encrypted.
     - parameter key The symmetric key
     - parameter iv The initialization vector
     
     returns: The encrypted data
     */
    class func encryptData(_ data:Data, key:Data, iv:Data) throws -> OTRCryptoData {
        if #available(iOS 13.0, *) {
            let nonce = try AES.GCM.Nonce(data: iv)
            let symmetricKey = SymmetricKey(data: key)
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: nonce)
            return OTRCryptoData(data: sealedBox.ciphertext, authTag: sealedBox.tag)
        } else {
            return try OTRCryptoUtility.encryptAESGCMData(data, key: key, iv: iv)
        }
    }
    
    /**
     Decrypt data with IV and key using aes-128-gcm
     
     - parameter data: The data to be decrypted.
     - parameter key The symmetric key
     - parameter iv The initialization vector
     
     returns: The Decrypted data
     */
    class func decryptData(_ data:Data, key:Data, iv:Data, authTag:Data) throws -> Data? {
        // CryptoKit only accepts 12-byte IVs
        if #available(iOS 13.0, *), iv.count == 12 {
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: data, tag: authTag)
            let symmetricKey = SymmetricKey(data: key)
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } else {
            let cryptoData = OTRCryptoData(data: data, authTag: authTag)
            return try OTRCryptoUtility.decryptAESGCMData(cryptoData, key: key, iv: iv)
        }
    }
    
    /** Generates random key of length 16 bytes*/
    class func generateSymmetricKey() -> Data? {
        return OTRPasswordGenerator.randomData(withLength: 16)
    }
    
    /** Generates random iv of length 12 bytes */
    class func generateIV() -> Data? {
        if #available(iOS 13.0, *) {
            return Data(AES.GCM.Nonce())
        } else {
            return OTRPasswordGenerator.randomData(withLength: 12)
        }
    }
    
}
