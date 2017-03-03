//
//  UIApplication+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 12/14/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import MWFeedParser
import UserNotifications
import OTRAssets

public extension UIApplication {
    
    public func showLocalNotification(_ message:OTRMessageProtocol) {
        var thread:OTRThreadOwner? = nil
        var unreadCount:UInt = 0
        
        OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.read({ (transaction) -> Void in
            unreadCount = transaction.numberOfUnreadMessages()
            thread = message.threadOwner(with: transaction)
        })
        
        guard let threadOwner = thread else {
            return
        }
        
        let threadName = threadOwner.threadName()
        
        var text = "\(threadName)"
        if let msgTxt = message.text() {
            if let rawMessageString = msgTxt.convertingHTMLToPlainText() {
                text += ": \(rawMessageString)"
            }
        }
        
        
        self.showLocalNotificationFor(threadOwner, text: text, unreadCount: Int(unreadCount))
    }
    
    public func showLocalNotificationForKnockFrom(_ thread:OTRThreadOwner?) {
        var name = SOMEONE_STRING()
        if let threadName = thread?.threadName() {
            name = threadName
        }
        
        let chatString = WANTS_TO_CHAT_STRING()
        let text = "\(name) \(chatString)"
        let unreadCount = self.applicationIconBadgeNumber + 1
        self.showLocalNotificationFor(thread, text: text, unreadCount: unreadCount)
    }
    
    internal func showLocalNotificationFor(_ thread:OTRThreadOwner?, text:String, unreadCount:Int?) {
        // Use the new UserNotifications.framework on iOS 10+
        if #available(iOS 10.0, *) {
            let localNotification = UNMutableNotificationContent()
            localNotification.body = text
            localNotification.badge = unreadCount as NSNumber?? ?? 0
            localNotification.sound = UNNotificationSound.default()
            if let t = thread {
                localNotification.threadIdentifier = t.threadIdentifier()
                localNotification.userInfo = [kOTRNotificationThreadKey:t.threadIdentifier(), kOTRNotificationThreadCollection:t.threadCollection()]
            }
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: localNotification, trigger: nil) // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: { (error: Error?) in
                if let error = error as? NSError {
                    #if DEBUG
                    NSLog("Error scheduling notification! %@", error)
                    #endif
                }
            })
        } else if(self.applicationState != .active) {
            let localNotification = UILocalNotification()
            localNotification.alertAction = REPLY_STRING()
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
