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
            
            let localNotification = UILocalNotification()
            localNotification.alertAction = OTRLanguageManager.translatedString("Reply")
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = Int(unreadCount)
            localNotification.alertBody = "\(threadName): \(rawMessageString)"
            
            localNotification.userInfo = [kOTRNotificationThreadKey:threadOwner.threadIdentifier(),kOTRNotificationThreadCollection:threadOwner.threadCollection()]
            
            self.presentLocalNotificationNow(localNotification)
        }
    }
    
}