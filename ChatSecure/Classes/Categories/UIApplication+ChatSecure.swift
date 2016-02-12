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
    
    public func showLocalNotification(message:OTRMesssageProtocol) {
        if (self.applicationState != .Active) {
            let rawMessageString = message.text().stringByConvertingHTMLToPlainText()
            
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
            
            let text = "\(threadName): \(rawMessageString)"
            
            self.showLocalNotificationFor(threadOwner, text: text, unreadCount: Int(unreadCount))
        }
    }
    
    public func showLocalNotificationForKnockFrom(thread:OTRThreadOwner) {
        let chatString = OTRLanguageManager.translatedString("wants to chat.")
        let text = "\(thread.threadName()) \(chatString)"
        let unreadCount = self.applicationIconBadgeNumber + 1
        self.showLocalNotificationFor(thread, text: text, unreadCount: unreadCount)
    }
    
    internal func showLocalNotificationFor(thread:OTRThreadOwner, text:String?, unreadCount:Int?) {
        if(self.applicationState != .Active) {
            
            let localNotification = UILocalNotification()
            localNotification.alertAction = OTRLanguageManager.translatedString("Reply")
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = unreadCount ?? 0
            localNotification.alertBody = text
            
            localNotification.userInfo = [kOTRNotificationThreadKey:thread.threadIdentifier(), kOTRNotificationThreadCollection:thread.threadCollection()]
            
            self.presentLocalNotificationNow(localNotification)
        }
    }
    
}