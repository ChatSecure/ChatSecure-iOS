//
//  OTRXMPPChangePasswordManager.swift
//  ChatSecure
//
//  Created by David Chiles on 12/9/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

open class OTRXMPPChangePasswordManager:NSObject {
    
    fileprivate let completion:(_ success:Bool,_ error:Error?) -> Void
    fileprivate let registrationModule:XMPPRegistration
    fileprivate let password:String
    fileprivate let xmppStream:XMPPStream
    
    @objc public init(newPassword:String, xmppStream:XMPPStream, completion:@escaping (_ success:Bool,_ error:Error?) -> Void) {
        self.registrationModule = XMPPRegistration()
        self.xmppStream = xmppStream
        self.registrationModule.activate(self.xmppStream)
        
        self.completion = completion
        self.password = newPassword;
        super.init()
        self.registrationModule.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    @objc open func changePassword() -> Bool {
        return self.registrationModule.changePassword(self.password)
    }
    
    deinit {
        registrationModule.removeDelegate(self)
        registrationModule.deactivate()
    }
}

extension OTRXMPPChangePasswordManager:XMPPRegistrationDelegate {
    
    public func passwordChangeSuccessful(_ sender: XMPPRegistration) {
        self.completion(true,nil)
    }
    
    public func passwordChangeFailed(_ sender: XMPPRegistration, withError error: Error?) {
        self.completion(false,error)
    }
}
