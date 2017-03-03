//
//  PushSerializer.swift
//  ChatSecure
//
//  Created by David Chiles on 9/24/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import ChatSecure_Push_iOS

enum jsonKeys: String {
    case endpoint = "endpoint"
    case tokens = "tokens"
    case extraData = "extra_data"
    case dateExpires = "date_expires"
}

open class PushSerializer: NSObject {
    
    open class func serialize(_ tokens:[Token], APIEndpoint:String) throws -> Data? {
        if tokens.count < 1 {
            return nil
        }
        var tokenStrings:[String] = []
        var expiresDate:[String?] = []
        for token in tokens {
            tokenStrings.append(token.tokenString)
            guard let date = token.expires else {
                throw NSError.chatSecureError(PushError.misingExpiresDate, userInfo: nil)
            }
            
            let dateString = Deserializer.dateFormatter().string(from: date)
            expiresDate.append(dateString)
        }
        
        let jsonDictionary = [jsonKeys.endpoint.rawValue: APIEndpoint, jsonKeys.tokens.rawValue: tokenStrings] as [String : Any]
        
        var data:Data? = nil
        do {
            data = try JSONSerialization.data(withJSONObject: jsonDictionary, options: JSONSerialization.WritingOptions())
        }catch {
            NSLog("JSON serialization Error")
        }
        
        return data
    }
}

