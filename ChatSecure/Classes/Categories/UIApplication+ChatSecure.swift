//
//  UIApplication+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 12/14/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import MWFeedParser


public extension UIApplication {
    
    public func showLocalNotification(message:OTRMessageProtocol) {
        if (self.applicationState != .Active) {
            
            
            var thread:OTRThreadOwner? = nil
            var unreadCount:UInt = 0
            
            OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection.readWithBlock({ (transaction) -> Void in
                unreadCount = transaction.numberOfUnreadMessages()
                thread = message.threadOwnerWithTransaction(transaction)
            })
            
            guard let threadOwner = thread else {
                return
            }
            
            let threadName = threadOwner.threadName()
            
            var text = "\(threadName)"
            if let msgTxt = message.text() {
                if let rawMessageString = msgTxt.stringByConvertingHTMLToPlainText() {
                    text += ": \(rawMessageString)"
                }
            }
            
            
            self.showLocalNotificationFor(threadOwner, text: text, unreadCount: Int(unreadCount))
        }
    }
    
    public func showLocalNotificationForKnockFrom(thread:OTRThreadOwner?) {
        var name = OTRLanguageManager.translatedString("Someone")
        if let threadName = thread?.threadName() {
            name = threadName
        }
        
        let chatString = OTRLanguageManager.translatedString("wants to chat.")
        let text = "\(name) \(chatString)"
        let unreadCount = self.applicationIconBadgeNumber + 1
        self.showLocalNotificationFor(thread, text: text, unreadCount: unreadCount)
    }
    
    internal func showLocalNotificationFor(thread:OTRThreadOwner?, text:String?, unreadCount:Int?) {
        if(self.applicationState != .Active) {
            
            let localNotification = UILocalNotification()
            localNotification.alertAction = OTRLanguageManager.translatedString("Reply")
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = unreadCount ?? 0
            localNotification.alertBody = text
            
            if let t = thread {
               localNotification.userInfo = [kOTRNotificationThreadKey:t.threadIdentifier(), kOTRNotificationThreadCollection:t.threadCollection()]
            }
            
            self.presentLocalNotificationNow(localNotification)
        }
    }
    
}