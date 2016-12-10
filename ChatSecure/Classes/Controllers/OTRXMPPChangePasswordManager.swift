//
//  OTRXMPPChangePasswordManager.swift
//  ChatSecure
//
//  Created by David Chiles on 12/9/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

public class OTRXMPPChangePasswordManager:NSObject {
    
    private let completion:(success:Bool,error:NSError?) -> Void
    private let registrationModule:XMPPRegistration
    private let password:String
    private let xmppStream:XMPPStream
    
    public init(newPassword:String, xmppStream:XMPPStream, completion:(success:Bool,error:NSError?) -> Void) {
        self.registrationModule = XMPPRegistration()
        self.xmppStream = xmppStream
        self.registrationModule.activate(self.xmppStream)
        
        self.completion = completion
        self.password = newPassword;
        super.init()
        self.registrationModule.addDelegate(self, delegateQueue: dispatch_get_main_queue())
    }
    
    private func changePassword() -> Bool {
        return self.registrationModule.changePassword(self.password)
    }
    
    deinit {
        registrationModule.removeDelegate(self)
        registrationModule.deactivate()
    }
}

extension OTRXMPPChangePasswordManager:XMPPRegistrationDelegate {
    
    public func passwordChangeSuccessful(sender: XMPPRegistration!) {
        self.completion(success: true,error: nil)
    }
    
    public func passwordChangeFailed(sender: XMPPRegistration!, withError error: NSError!) {
        self.completion(success:false,error:error)
    }
}
