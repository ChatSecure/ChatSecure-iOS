//
//  PushDeserializer.swift
//  ChatSecure
//
//  Created by David Chiles on 9/24/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS

open class PushDeserializer: NSObject  {
    
    open class func deserializeToken(_ data:Data) throws -> [TokenContainer] {
        guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? [String:AnyObject] else {
            throw NSError.chatSecureError(PushError.invalidJSON, userInfo: nil)
        }
        
        guard let apiEndPoint = jsonDictionary[jsonKeys.endpoint.rawValue] as? String else {
            throw NSError.chatSecureError(PushError.missingAPIEndpoint, userInfo: nil)
        }
        
        let apiURL = URL(string: apiEndPoint)
        
        guard let tokenStrings = jsonDictionary[jsonKeys.tokens.rawValue] as? [String] else {
            throw NSError.chatSecureError(PushError.missingTokens, userInfo: nil)
        }
        
        var tokenArray:[TokenContainer] = []
        for tokenString in tokenStrings {
            let pushToken = Token(tokenString: tokenString,type: .unknown, deviceID: nil)
            if let tokenContainer = TokenContainer() {
                tokenContainer.pushToken = pushToken
                tokenContainer.endpoint = apiURL
                tokenArray.append(tokenContainer)
            }
        }
        
        return tokenArray
    }
}
