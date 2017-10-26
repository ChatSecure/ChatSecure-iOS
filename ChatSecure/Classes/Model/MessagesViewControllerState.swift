//
//  MessagesViewControllerState.swift
//  ChatSecure
//
//  Created by David Chiles on 2/23/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

/// A simple model to encompass all the possible states that affect the send button. In the future this could have more properties for the lock and title bar
@objc open class MessagesViewControllerState:NSObject {
    
    /** This should reflect whether the textview currently has text */
    @objc open var hasText = false
    
    /** This should reflect if the current thread can send a knock message and therefore show knock UI */
    @objc open var canKnock = false
    
    /** Reflects media messages can be send. Right now OTRData is only supported so based on if OTR session exists */
    @objc open var canSendMedia = false
    
    /** This should reflect how messages should be sent and what the buddy prefrences are */
    @objc open var messageSecurity = OTRMessageTransportSecurity.plaintext
    
    /** This should reflect if the thread(buddy) is online or not so show knock UI or not. */
    @objc open var isThreadOnline = false
}
