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

public enum NotificationType {
    case subscriptionRequest
    case approvedBuddy
    case connectionError
    case chatMessage
}

extension NotificationType: RawRepresentable {
    public init?(rawValue: String) {
        if rawValue == kOTRNotificationTypeSubscriptionRequest {
            self = .subscriptionRequest
        } else if rawValue == kOTRNotificationTypeApprovedBuddy {
            self = .approvedBuddy
        } else if rawValue == kOTRNotificationTypeChatMessage {
            self = .chatMessage
        } else if rawValue == kOTRNotificationTypeConnectionError {
            self = .connectionError
        } else {
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .subscriptionRequest:
            return kOTRNotificationTypeSubscriptionRequest
        case .approvedBuddy:
            return kOTRNotificationTypeApprovedBuddy
        case .connectionError:
            return kOTRNotificationTypeConnectionError
        case .chatMessage:
            return kOTRNotificationTypeChatMessage
        }
    }
    
    public typealias RawValue = String
}

extension UIApplication {
    
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
                    //DDLogVerbose("notification delivered: \(notification)")
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
    
    @objc public func showLocalNotification(_ message:OTRMessageProtocol, transaction: YapDatabaseReadTransaction) {
        guard let thread = message.threadOwner(with: transaction) else {
            return
        }
        var unreadCount:UInt = 0
        var mediaItem: OTRMediaItem? = nil
        unreadCount = transaction.numberOfUnreadMessages()
        mediaItem = OTRMediaItem.init(forMessage: message, transaction: transaction)
        let threadName = thread.threadName
        
        var text = "\(threadName)"
        
        // Show author of group messages
        if thread.isGroupThread,
            let displayName = message.buddy(with: transaction)?.displayName,
                displayName.count > 0 {
            text += " (\(displayName))"
        }
        
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
        
        self.showLocalNotificationFor(thread, text: text, unreadCount: Int(unreadCount))
    }
    
    @objc public func showLocalNotificationForKnockFrom(_ thread:OTRThreadOwner?) {
        DispatchQueue.main.async {
            var name = SOMEONE_STRING()
            if let threadName = thread?.threadName {
                name = threadName
            }
            
            let chatString = WANTS_TO_CHAT_STRING()
            let text = "\(name) \(chatString)"
            let unreadCount = self.applicationIconBadgeNumber + 1
            self.showLocalNotificationFor(thread, text: text, unreadCount: unreadCount)
        }
    }
    
    @objc public func showLocalNotificationForSubscriptionRequestFrom(_ jid:String?) {
        DispatchQueue.main.async {
            var name = SOMEONE_STRING()
            if let jidName = jid {
                name = jidName
            }
            
            let chatString = WANTS_TO_CHAT_STRING()
            let text = "\(name) \(chatString)"
            let unreadCount = self.applicationIconBadgeNumber + 1
            self.showLocalNotificationWith(groupingIdentifier: nil, body: text, badge: unreadCount, userInfo: [kOTRNotificationType:kOTRNotificationTypeSubscriptionRequest], recurring: false)
        }
    }
    
    @objc public func showLocalNotificationForApprovedBuddy(_ thread:OTRThreadOwner?) {
        guard let thread = thread, !thread.isMuted else { return } // No notifications for muted
        DispatchQueue.main.async {
            var name = SOMEONE_STRING()
            if let buddyName = (thread as? OTRBuddy)?.displayName {
                name = buddyName
            } else if !thread.threadName.isEmpty {
                name = thread.threadName
            }
            
            let message = String(format: BUDDY_APPROVED_STRING(), name)
            let unreadCount = self.applicationIconBadgeNumber + 1
            let identifier = thread.threadIdentifier
            let userInfo:[AnyHashable:Any] = [kOTRNotificationThreadKey:identifier,
                                              kOTRNotificationThreadCollection:thread.threadCollection,
                                              kOTRNotificationType: kOTRNotificationTypeApprovedBuddy]
            self.showLocalNotificationWith(groupingIdentifier: nil, body: message, badge: unreadCount, userInfo: userInfo, recurring: false)
        }
    }
    
    internal func showLocalNotificationFor(_ thread:OTRThreadOwner?, text:String, unreadCount:Int) {
        if let thread = thread, thread.isMuted { return } // No notifications for muted
        DispatchQueue.main.async {
            var userInfo:[AnyHashable:Any]? = nil
            if let t = thread {
                userInfo = [kOTRNotificationThreadKey:t.threadIdentifier,
                            kOTRNotificationThreadCollection:t.threadCollection,
                            kOTRNotificationType: kOTRNotificationTypeChatMessage]
            }
            self.showLocalNotificationWith(groupingIdentifier: nil, body: text, badge: unreadCount, userInfo: userInfo, recurring: false)
        }
    }
    
    @objc public func showLocalNotificationWith(groupingIdentifier:String?, body:String, badge:Int, userInfo:[AnyHashable:Any]?, recurring:Bool) {
        DispatchQueue.main.async {
            if recurring, self.hasRecurringLocalNotificationWith(identifier: groupingIdentifier) {
                return // Already pending
            }
            // Use the new UserNotifications.framework on iOS 10+
            if #available(iOS 10.0, *) {
                let localNotification = UNMutableNotificationContent()
                localNotification.body = body
                localNotification.badge = NSNumber(integerLiteral: badge)
                localNotification.sound = UNNotificationSound.default
                if let threadKey = userInfo?[kOTRNotificationThreadKey] as? String {
                    localNotification.threadIdentifier = threadKey
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
                let request = UNNotificationRequest(identifier: groupingIdentifier ?? UUID().uuidString, content: localNotification, trigger: trigger) // Schedule the notification.
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
    
    /// show a notification when there is an issue connecting, for instance expired certificate
    @objc public func showConnectionErrorNotification(account: OTRXMPPAccount, error: NSError) {
        let username = account.username
        var body = "\(CONNECTION_ERROR_STRING()) \(username)."
        
        if error.domain == GCDAsyncSocketErrorDomain,
            let code = GCDAsyncSocketError(rawValue: error.code) {
            
            switch code {
            case .noError,
                 .connectTimeoutError,
                 .readTimeoutError,
                 .writeTimeoutError,
                 .readMaxedOutError,
                 .closedError:
                return
            case .badConfigError, .badParamError:
                body = body + " \(error.localizedDescription)."
            case .otherError:
                // this is probably a SSL error
                body = body + " \(CONNECTION_ERROR_CERTIFICATE_VERIFY_STRING())"
            @unknown default:
                return
            }
        } else if error.domain == "kCFStreamErrorDomainSSL" {
            body = body + " \(CONNECTION_ERROR_CERTIFICATE_VERIFY_STRING())"
            let osStatus = OSStatus(error.code)
            
            // Ignore a few SSL error codes that might be more annoying than useful
            //                errSSLClosedGraceful         = -9805,    /* connection closed gracefully */
            //                errSSLClosedAbort             = -9806,    /* connection closed via error */
            let codesToIgnore = [errSSLClosedAbort, errSSLClosedGraceful]
            if codesToIgnore.contains(osStatus) {
                return
            }
            
            if let sslString = OTRXMPPError.errorString(withSSLStatus: osStatus) {
                body = body + " \"\(sslString)\""
            }
        } else {
            // unrecognized error domain... ignoring
            return
        }
        
        let accountKey = account.uniqueId
        let badge = UIApplication.shared.applicationIconBadgeNumber + 1
        
        let userInfo = [kOTRNotificationType: kOTRNotificationTypeConnectionError,
                        kOTRNotificationAccountKey: accountKey]
        
        self.showLocalNotificationWith(groupingIdentifier: accountKey, body: body, badge: badge, userInfo: userInfo, recurring: false)
    }
}

extension UIApplication {
    @objc public func open(_ url: URL) {
        open(url, options: [:], completionHandler: nil)
    }
}
