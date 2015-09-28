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
}

public class PushSerializer: NSObject {
    
    public class func serialize(tokens:[Token], APIEndpoint:String) -> NSData? {
        if tokens.count < 1 {
            return nil
        }
        var tokenStrings:[String] = []
        for token in tokens {
            tokenStrings.append(token.tokenString)
        }
        
        let jsonDictionary = [jsonKeys.endpoint.rawValue: APIEndpoint, jsonKeys.tokens.rawValue: tokenStrings]
        
        var data:NSData? = nil
        do {
            data = try NSJSONSerialization.dataWithJSONObject(jsonDictionary, options: NSJSONWritingOptions())
        }catch {
            NSLog("JSON serialization Error")
        }
        
        return data
    }
}

