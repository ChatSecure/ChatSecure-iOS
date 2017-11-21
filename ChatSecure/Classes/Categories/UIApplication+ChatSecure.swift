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
    
    /// Removes all but one foreground notifications for typing and message events sent from APNS
    @objc public func removeExtraForegroundNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                var newMessageIdentifiers: [String] = []
                var typingIdentifiers: [String] = []
                
                notifications.forEach { notification in
                    if notification.request.content.body == NEW_MESSAGE_STRING() {
                        newMessageIdentifiers.append(notification.request.identifier)
                    } else if notification.request.content.body == SOMEONE_IS_TYPING_STRING() {
                        typingIdentifiers.append(notification.request.identifier)
                    }
                    DDLogVerbose("notification delivered: \(notification)")
                }
                if newMessageIdentifiers.count > 1 {
                    _ = newMessageIdentifiers.popLast()
                }
                if typingIdentifiers.count > 1 {
                    _ = typingIdentifiers.popLast()
                }
                let allIdentifiers = newMessageIdentifiers + typingIdentifiers
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: allIdentifiers)
            }
        }
    }
    
    @objc public func showLocalNotification(_ message:OTRMessageProtocol) {
        var thread:OTRThreadOwner? = nil
        var unreadCount:UInt = 0
        var mediaItem: OTRMediaItem? = nil
        OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.read({ (transaction) -> Void in
            unreadCount = transaction.numberOfUnreadMessages()
            thread = message.threadOwner(with: transaction)
            mediaItem = OTRMediaItem.init(forMessage: message, transaction: transaction)
        })
        guard let threadOwner = thread else {
            return
        }
        let threadName = threadOwner.threadName
        
        var text = "\(threadName)"
        
        if let mediaItem = mediaItem {
            let mediaText = mediaItem.displayText()
            text += ": \(mediaText)"
        } else if let msgTxt = message.messageText,
            let rawMessageString = msgTxt.convertingHTMLToPlainText() {
            // Bail out of notification if this is an incoming encrypted file transfer
            if msgTxt.contains("aesgcm://") {
                return
            }
            text += ": \(rawMessageString)"
        } else {
            return
        }
        
        self.showLocalNotificationFor(threadOwner, text: text, unreadCount: Int(unreadCount))
    }
    
    @objc public func showLocalNotificationForKnockFrom(_ thread:OTRThreadOwner?) {
        var name = SOMEONE_STRING()
        if let threadName = thread?.threadName {
            name = threadName
        }
        
        let chatString = WANTS_TO_CHAT_STRING()
        let text = "\(name) \(chatString)"
        let unreadCount = self.applicationIconBadgeNumber + 1
        self.showLocalNotificationFor(thread, text: text, unreadCount: unreadCount)
    }
    
    @objc public func showLocalNotificationForSubscriptionRequestFrom(_ jid:String?) {
        var name = SOMEONE_STRING()
        if let jidName = jid {
            name = jidName
        }
        
        let chatString = WANTS_TO_CHAT_STRING()
        let text = "\(name) \(chatString)"
        let unreadCount = self.applicationIconBadgeNumber + 1
        self.showLocalNotificationWith(identifier: nil, body: text, badge: unreadCount, userInfo: [kOTRNotificationType:kOTRNotificationTypeSubscriptionRequest], recurring: false)
    }
    
    @objc public func showLocalNotificationForApprovedBuddy(_ thread:OTRThreadOwner?) {
        var name = SOMEONE_STRING()
        if let buddyName = (thread as? OTRBuddy)?.displayName {
            name = buddyName
        } else if let threadName = thread?.threadName {
            name = threadName
        }
        
        let message = String(format: BUDDY_APPROVED_STRING(), name)
        
        let unreadCount = self.applicationIconBadgeNumber + 1
        self.showLocalNotificationFor(thread, text: message, unreadCount: unreadCount)
    }
    
    internal func showLocalNotificationFor(_ thread:OTRThreadOwner?, text:String, unreadCount:Int) {
        if let thread = thread, thread.isMuted { return } // No notifications for muted
        DispatchQueue.main.async {
            var identifier:String? = nil
            var userInfo:[AnyHashable:Any]? = nil
            if let t = thread {
                identifier = t.threadIdentifier
                userInfo = [kOTRNotificationThreadKey:t.threadIdentifier, kOTRNotificationThreadCollection:t.threadCollection]
            }
            self.showLocalNotificationWith(identifier: identifier, body: text, badge: unreadCount, userInfo: userInfo, recurring: false)
        }
    }
    
    @objc public func showLocalNotificationWith(identifier:String?, body:String, badge:Int, userInfo:[AnyHashable:Any]?, recurring:Bool) {
        DispatchQueue.main.async {
            if recurring, self.hasRecurringLocalNotificationWith(identifier: identifier) {
                return // Already pending
            }
            // Use the new UserNotifications.framework on iOS 10+
            if #available(iOS 10.0, *) {
                let localNotification = UNMutableNotificationContent()
                localNotification.body = body
                localNotification.badge = NSNumber(integerLiteral: badge)
                localNotification.sound = UNNotificationSound.default()
                if let identifier = identifier {
                    localNotification.threadIdentifier = identifier
                }
                if let userInfo = userInfo {
                    localNotification.userInfo = userInfo
                }
                var trigger:UNNotificationTrigger? = nil
                if recurring {
                    var date = DateComponents()
                    date.hour = 11
                    date.minute = 0
                    trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
                }
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: localNotification, trigger: trigger) // Schedule the notification.
                let center = UNUserNotificationCenter.current()
                center.add(request, withCompletionHandler: { (error: Error?) in
                    if let error = error as NSError? {
                        #if DEBUG
                            NSLog("Error scheduling notification! %@", error)
                        #endif
                    }
                })
            } else if recurring || self.applicationState != .active {
                let localNotification = UILocalNotification()
                localNotification.alertAction = REPLY_STRING()
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = badge
                localNotification.alertBody = body
                if let userInfo = userInfo {
                    localNotification.userInfo = userInfo
                }
                if recurring {
                    var date = DateComponents()
                    date.hour = 11
                    date.minute = 0
                    localNotification.repeatInterval = .day
                    localNotification.fireDate = NSCalendar.current.date(from: date)
                    self.scheduleLocalNotification(localNotification)
                } else {
                    self.presentLocalNotificationNow(localNotification)
                }
            }
        }
    }
    
    @objc public func hasRecurringLocalNotificationWith(identifier:String?) -> Bool {
        return hasRecurringLocalNotificationWith(identifier:identifier, cancelIfFound:false)
    }

    @objc @discardableResult public func cancelRecurringLocalNotificationWith(identifier:String?) -> Bool {
        return hasRecurringLocalNotificationWith(identifier:identifier, cancelIfFound:true)
    }

    func hasRecurringLocalNotificationWith(identifier:String?, cancelIfFound:Bool) -> Bool {
            guard let identifier = identifier else { return false }

        var found = false
        
        // Use the new UserNotifications.framework on iOS 10+
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests:[UNNotificationRequest]) in
                for request in requests {
                    let userInfo = request.content.userInfo
                    if let threadKey =
                        userInfo[kOTRNotificationThreadKey] as? String, threadKey == identifier {
                        found = true
                        if cancelIfFound {
                            let center = UNUserNotificationCenter.current()
                            center.removePendingNotificationRequests(withIdentifiers:[request.identifier])
                        }
                    }
                }
            })
        } else {
            if let notifications = self.scheduledLocalNotifications {
                for notification in notifications {
                    if let userInfo = notification.userInfo, let threadKey =
                        userInfo[kOTRNotificationThreadKey] as? String, threadKey == identifier {
                        found = true
                        if cancelIfFound {
                            self.cancelLocalNotification(notification)
                        }
                    }
                }
            }
        }
        return found
    }
}
