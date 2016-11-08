//
//  MessagesViewControllerState.swift
//  ChatSecure
//
//  Created by David Chiles on 2/23/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import Foundation

/// A simple model to encompass all the possible states that affect the send button. In the future this could have more properties for the lock and title bar
@objc public class MessagesViewControllerState:NSObject {
    
    /** This should reflect whether the textview currently has text */
    public var hasText = false
    
    /** This should reflect if the current thread can send a knock message and therefore show knock UI */
    public var canKnock = false
    
    /** Reflects media messages can be send. Right now OTRData is only supported so based on if OTR session exists */
    public var canSendMedia = false
    
    /** This should reflect how messages should be sent and what the buddy prefrences are */
    public var messageSecurity = OTRMessageTransportSecurity.Plaintext
    
    /** This should reflect if the thread(buddy) is online or not so show knock UI or not. */
    public var isThreadOnline = false
}
