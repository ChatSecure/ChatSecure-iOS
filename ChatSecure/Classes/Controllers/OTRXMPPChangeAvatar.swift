//
//  OTRXMPPChangeAvatar.swift
//  ChatSecure
//
//  Created by David Chiles on 1/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

@objc public class OTRXMPPChangeAvatar: NSObject {
    
    public weak var xmppvCardTempModule:XMPPvCardTempModule?
    public let photoData:NSData
    private let workQueue = dispatch_queue_create("OTRXMPPChangeAvatar-workQueue", DISPATCH_QUEUE_SERIAL)
    
    private var waitingForVCardFetch:Bool = false
    private var completion:((Bool)->Void)?
    
    public init(photoData:NSData, xmppvCardTempModule:XMPPvCardTempModule?) {
        self.photoData = photoData
        self.xmppvCardTempModule = xmppvCardTempModule
        super.init()
        self.xmppvCardTempModule?.addDelegate(self, delegateQueue: self.workQueue)
    }
    /**
     This does the actual work of updating the vCard fot the sterams myJID.
     First it makes sure it has an up to date vCard
     **/
    public func updatePhoto(completion:(success:Bool)->Void) -> Void {
        
        //make sure the stream is authenticated
        guard let isAuthenticated = self.xmppvCardTempModule?.xmppStream.isAuthenticated() where isAuthenticated == true else {
            dispatch_async(dispatch_get_main_queue(), { 
                completion(success:false)
                self.completion = nil
            })
            return
        }
        self.completion = completion
        
        dispatch_async(self.workQueue) { [weak self] in
            // Ensure you have the objects we need.
            // * Strong reference to self
            // * The vCardModule to do teh work of updaing and fetching
            // * myJID for fetching
            guard let strongSelf = self,
                vCardModule = self?.xmppvCardTempModule, myJID = vCardModule.xmppStream.myJID  else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(success:false)
                        self?.completion = nil
                    })
                return
            }
            
            //Check if we get a vCard from the storage otherwise it should fetch from the server
            guard let vCard = vCardModule.vCardTempForJID(myJID, shouldFetch: true) else {
                // Nothing came back from the storage so we're fetching from teh server.
                strongSelf.waitingForVCardFetch = true
                return
            }
            
            //We have a vCard so update with photo data and send to server and storage.
            strongSelf.waitingForVCardFetch = false
            vCard.photo = strongSelf.photoData
            vCardModule.updateMyvCardTemp(vCard)
            dispatch_async(dispatch_get_main_queue(), {
                completion(success:true)
                strongSelf.completion = nil
            })
        }
    }
    
}

extension OTRXMPPChangeAvatar: XMPPvCardTempModuleDelegate {
    public func xmppvCardTempModuleDidUpdateMyvCard(vCardTempModule: XMPPvCardTempModule!) {
        //If we have a completion block
        if let completion = self.completion where self.waitingForVCardFetch == true {
            // call update again. This time there should be a vcard in the storage and we'll be able to update
            self.updatePhoto(completion)
        }
        self.waitingForVCardFetch = false
    }
    
    public func xmppvCardTempModule(vCardTempModule: XMPPvCardTempModule!, failedToUpdateMyvCard error: DDXMLElement!) {
        
        self.waitingForVCardFetch = false
        
        if let completion = self.completion {
            dispatch_async(dispatch_get_main_queue(), {
                completion(false)
                self.completion = nil
            })
        }
        
       
    }
}
