//
//  OTRXMPPChangeAvatar.swift
//  ChatSecure
//
//  Created by David Chiles on 1/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

@objc open class OTRXMPPChangeAvatar: NSObject {
    
    open weak var xmppvCardTempModule:XMPPvCardTempModule?
    public let photoData:Data
    fileprivate let workQueue = DispatchQueue(label: "OTRXMPPChangeAvatar-workQueue", attributes: [])
    
    fileprivate var waitingForVCardFetch:Bool = false
    fileprivate var completion:((Bool)->Void)?
    
    @objc public init(photoData:Data, xmppvCardTempModule:XMPPvCardTempModule?) {
        self.photoData = photoData
        self.xmppvCardTempModule = xmppvCardTempModule
        super.init()
        self.xmppvCardTempModule?.addDelegate(self, delegateQueue: self.workQueue)
    }
    /**
     This does the actual work of updating the vCard fot the stream's myJID.
     First it makes sure it has an up to date vCard
     **/
    @objc open func updatePhoto(_ completion:@escaping (_ success:Bool)->Void) -> Void {
        
        //make sure the stream is authenticated
        guard let isAuthenticated = self.xmppvCardTempModule?.xmppStream?.isAuthenticated, isAuthenticated == true else {
            DispatchQueue.main.async(execute: { 
                completion(false)
                self.completion = nil
            })
            return
        }
        self.completion = completion
        
        self.workQueue.async { [weak self] in
            // Ensure you have the objects we need.
            // * Strong reference to self
            // * The vCardModule to do teh work of updaing and fetching
            // * myJID for fetching
            guard let strongSelf = self,
                let vCardModule = self?.xmppvCardTempModule, let myJID = vCardModule.xmppStream?.myJID  else {
                    DispatchQueue.main.async(execute: {
                        completion(false)
                        self?.completion = nil
                    })
                return
            }
            
            //Check if we get a vCard from the storage otherwise it should fetch from the server
            guard let vCard = vCardModule.vCardTemp(for: myJID, shouldFetch: true) else {
                // Nothing came back from the storage so we're fetching from teh server.
                strongSelf.waitingForVCardFetch = true
                return
            }
            
            //We have a vCard so update with photo data and send to server and storage.
            strongSelf.waitingForVCardFetch = false
            vCard.photo = strongSelf.photoData
            vCardModule.updateMyvCardTemp(vCard)
            DispatchQueue.main.async(execute: {
                completion(true)
                strongSelf.completion = nil
            })
        }
    }
    
}

extension OTRXMPPChangeAvatar: XMPPvCardTempModuleDelegate {
    public func xmppvCardTempModuleDidUpdateMyvCard(_ vCardTempModule: XMPPvCardTempModule) {
        //If we have a completion block
        if let completion = self.completion, self.waitingForVCardFetch == true {
            // call update again. This time there should be a vcard in the storage and we'll be able to update
            self.updatePhoto(completion)
        }
        self.waitingForVCardFetch = false
    }
    
    public func xmppvCardTempModule(_ vCardTempModule: XMPPvCardTempModule, failedToUpdateMyvCard error: XMLElement?) {
        
        self.waitingForVCardFetch = false
        
        if let completion = self.completion {
            DispatchQueue.main.async(execute: {
                completion(false)
                self.completion = nil
            })
        }
        
       
    }
}
