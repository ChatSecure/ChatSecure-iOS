//
//  PushDeserializer.swift
//  ChatSecure
//
//  Created by David Chiles on 9/24/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS

public class PushDeserializer: NSObject  {
    
    public class func deserializeToken(data:NSData) throws -> [TokenContainer] {
        guard let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? [String:AnyObject] else {
            throw PushError.invalidJSON.error()
        }
        
        guard let apiEndPoint = jsonDictionary[jsonKeys.endpoint.rawValue] as? String else {
            throw PushError.missingAPIEndpoint.error()
        }
        
        let apiURL = NSURL(string: apiEndPoint)
        
        guard let tokenStrings = jsonDictionary[jsonKeys.tokens.rawValue] as? [String] else {
            throw PushError.missingTokens.error()
        }
        
        var tokenArray:[TokenContainer] = []
        for tokenString in tokenStrings {
            let pushToken = Token(tokenString: tokenString, deviceID: nil)
            let tokenContainer = TokenContainer()
            tokenContainer.pushToken = pushToken
            tokenContainer.endpoint = apiURL
            tokenArray.append(tokenContainer)
        }
        
        return tokenArray
    }
}